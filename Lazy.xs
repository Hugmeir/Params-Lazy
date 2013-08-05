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
    I32 i;
    /* PL_curstack and PL_stack_sp in the delayed OPs */
    AV *delayed_curstack;
    SV **delayed_sp;

    SAVEOP();
    SAVECOMPPAD();

    PUSHSTACK;

    /* The SAVECOMPPAD and SAVEOP will restore these */
    PL_curpad  = AvARRAY(ctx->comppad);
    PL_comppad = ctx->comppad;
    PL_op      = ctx->delayed;
    
    PUSHMARK(PL_stack_sp);
    
    IV before = (IV)(PL_stack_sp-PL_stack_base);

    /* Call the deferred ops */
    CALLRUNOPS(aTHX);

    //SPAGAIN;

    IV retvals = (IV)(PL_stack_sp-PL_stack_base);

    /* Keep a pointer to PL_curstack, and increase the
     * refcount so that it doesn't get freed in the
     * POPSTACK below.
     * Also keep a pointer to PL_stack_sp so we can copy
     * the values at the end.
     */
    if ( retvals && gimme != G_VOID ) {
        delayed_curstack = MUTABLE_AV(SvREFCNT_inc_simple_NN(PL_curstack));
        delayed_sp = PL_stack_sp;

        /* This has two uses.  First, it stops these from
         * being freed early after the FREETMPS/POPSTACK;
         * second, this is the ref we mortalize later,
         * with the mPUSHs
         */
        for (i = retvals; i > before; i--) {
            SvREFCNT_inc_simple_void_NN(*(PL_stack_sp-i+1));
        }
    }

    (void)POPMARK;
    POPSTACK;
    SPAGAIN;
    
    PUSHMARK(SP);
    
    (void)POPs;

    if ( retvals && gimme != G_VOID ) {
        EXTEND(SP, retvals);
        
        for (i = retvals; i-- > before;) {
            mPUSHs(*(delayed_sp-i));
        }
        SvREFCNT_dec(delayed_curstack);
    }
    
    (void)POPMARK;

    