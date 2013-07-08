#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct {
 OP *delayed;
 
 AV *comppad;
} delay_ctx;

static int magic_free(pTHX_ SV *sv, MAGIC *mg)
{
  delay_ctx *ctx = (void *)mg->mg_ptr;
 
  PERL_UNUSED_ARG(sv);
 
  op_free((OP*)ctx->delayed);
  Safefree(ctx);
 
  return 1;
}
 
static MGVTBL vtbl = {
  NULL, /* get */
  NULL, /* set */
  NULL, /* len */
  NULL, /* clear */
  &magic_free,
#ifdef MGf_COPY
  NULL, /* copy */
#endif
#ifdef MGf_DUP
  NULL, /* dup */
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};

STATIC OP *
replace_with_delayed(pTHX_ OP* aop) {
    OP* new_op;
    OP* const kid = aop;
    OP* const sib = kid->op_sibling;
    SV* magic_sv  = newSVpvs("STATEMENT");
    OP *listop;
    delay_ctx *ctx;

    Newx(ctx, 1, delay_ctx);

    /* Disconnect the op we're delaying, then wrap it in
     * a OP_LIST
     */
    kid->op_sibling = 0;

    listop = newLISTOP(OP_LIST, 0, kid, (OP*)NULL);
    LINKLIST(listop);

    /* Stop it from looping */
    cUNOPx(kid)->op_next = (OP*)NULL;

    /* Make GIMME in the deferred op be OPf_WANT_LIST */
    Perl_list(aTHX_ listop);
    
    ctx->delayed = (OP*)listop;

    /* We use this to restore the context the ops were
     * originally running in */
    ctx->comppad = PL_comppad;

    /* Magicalize the scalar, */
    sv_magicext(magic_sv, (SV*)NULL, PERL_MAGIC_ext, &vtbl, (const char *)ctx, 0);

    /* Then put that in place of the OPs we removed, but wrap
     * as a ref.
     */
    new_op = (OP*)newSVOP(OP_CONST, 0, newRV(magic_sv));
    new_op->op_sibling = sib;
    return new_op;
}

STATIC OP *
THX_ck_entersub_args_delay(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    SV *proto            = newSVsv(ckobj);
    STRLEN protolen, len = 0;
    char * protopv       = SvPV(proto, protolen);
    OP *aop, *prev;
    
    PERL_UNUSED_ARG(namegv);
    
    aop = cUNOPx(entersubop)->op_first;
    
    if (!aop->op_sibling)
        aop = cUNOPx(aop)->op_first;
    
    prev = aop;
    
    for (aop = aop->op_sibling; aop->op_sibling; aop = aop->op_sibling) {
        if ( len < protolen && protopv[len] == '^' ) {
            aop = replace_with_delayed(aTHX_ aop);
            prev->op_sibling = aop;
            
            protopv[len] = '$';
        }
        prev = aop;
        len++;
    }
    
    return ck_entersub_args_proto(entersubop, namegv, proto);
}

MODULE = Params::Lazy		PACKAGE = Params::Lazy		

void
cv_set_call_checker_delay(CV *cv, SV *proto)
CODE:
    cv_set_call_checker(cv, THX_ck_entersub_args_delay, proto);

void
force(SV *sv)
PPCODE:
    dSP;
    
    MAGIC *mg       = SvMAGIC(SvRV(sv));
    delay_ctx *ctx  = (void *)mg->mg_ptr;
    const I32 gimme = GIMME_V;
    AV *tmpstack    = MUTABLE_AV(sv_2mortal(newSV_type(SVt_PVAV)));
    AV * orig_mainstack = PL_mainstack;
    AV *curstack    = PL_curstack;
    I32 i;
    
    ENTER;

    SAVEVPTR(PL_op);
    SAVEVPTR(PL_markstack);
    SAVEVPTR(PL_markstack_ptr);
    SAVEVPTR(PL_markstack_max);
    SAVECOMPPAD();

    av_push(tmpstack, &PL_sv_undef);

    /* We want the deferred ops to have their original stack, but
     * can't use that directly since we could step on newer stuff.
     * So tell curstackinfo that we're using the old stack, but set
     * PL_curstack to the AV we created above */
    SWITCHSTACK(PL_curstack,tmpstack);
    //PL_curstackinfo     = ctx->si;
    
    /* XXX TODO WIP this is in case the deferred ops die,
     * currently works by luck and snake oil */
    PL_mainstack = tmpstack;
    
    PL_stack_base   = AvARRAY(tmpstack);
    PL_stack_sp     = PL_stack_base;
    PL_stack_max    = PL_stack_base + AvMAX(tmpstack);
    
    Newxz(PL_markstack, 32, I32);
    PL_markstack_ptr = PL_markstack;
    PL_markstack_max = PL_markstack + 32;
    
    /* The SAVECOMPPAD above will restore these */
    PL_curpad  = AvARRAY(ctx->comppad);
    PL_comppad = ctx->comppad;

    /* SAVEVPTR will restore this */
    PL_op = ctx->delayed;
    
    PUTBACK;
    SPAGAIN;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    
    IV before = (IV)(SP-PL_stack_base);

    /* Call the deferred ops */
    CALLRUNOPS(aTHX);

    SPAGAIN;

    IV retvals = (IV)(SP-PL_stack_base);

    /* We want these to stay alive until after we've
     * switched the stack back so we can copy them over
     */    
    if ( gimme != G_VOID ) {
      for (i = retvals; i > before; i--) {
        SvREFCNT_inc_simple_void_NN(*(SP-i+1));
      }
    }

    FREETMPS;
    PUTBACK;
    LEAVE;

    /* Undo everything we did before */
    PL_mainstack = orig_mainstack;

    SWITCHSTACK(PL_curstack,curstack);

    PL_stack_base    = AvARRAY(PL_curstack);
    PL_stack_sp      = PL_stack_base + AvFILLp(PL_curstack);
    PL_stack_max     = PL_stack_base + AvMAX(PL_curstack);
    
    Safefree(PL_markstack);

    PUTBACK;
    SPAGAIN;
    LEAVE;
    
    PUSHMARK(SP);
    
    (void)POPs;
 
    if ( gimme != G_VOID ) {
        EXTEND(SP, retvals);
    
        SV **mysp = AvARRAY(tmpstack);
        for (i = before; i++ < retvals; i) {
          SvREFCNT_inc_simple_void_NN(*(mysp+i));
          mPUSHs(*(mysp+i));
        }
    }

    (void)POPMARK;

    