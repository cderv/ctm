library("tramME")

chktol <- function(x, y, tol = sqrt(.Machine$double.eps))
  stopifnot(isTRUE(all.equal(x, y, tolerance = tol, check.attributes = FALSE)))

chkerr <- function(expr) inherits(try(expr, silent = TRUE), "try-error")

## covariance matrix of the parameters
data("sleepstudy", package = "lme4")
fit <- BoxCoxME(Reaction ~ Days + (Days | Subject), data = sleepstudy, order = 5)
fit2 <- fit
varcov(fit2) <- list(diag(1:2)) ## just to make it unfitted
chkerr(vcov(fit2))
vc <- vcov(fit, pargroup = "baseline")
chktol(dim(vc), c(6, 6))
chktol(vc, vcov(fit, parm = "Reaction", pmatch = TRUE))
chktol(dim(vcov(fit, 1:2, "ranef")), c(2, 2))
chktol(dim(vcov(fit, c(1, 10, 20), "shift")), c(1, 1))
chktol(dim(vcov(fit, parm = c("foo", "bar"))), c(0, 0))

## random effects
data("eortc", package = "coxme")
library("survival")
fit <- CoxphME(Surv(y, uncens) ~ trt + (1 | center/trt), data = eortc,
               log_first = TRUE, order = 5)
re <- ranef(fit, raw = TRUE)
chktol(length(re), sum(fit$model$ranef$termsize))
re <- ranef(fit, condVar = TRUE)
chktol(sapply(re, nrow), fit$model$ranef$termsize)

fit <- LmME(Reaction ~ Days + (Days || Subject), data = sleepstudy)
re <- ranef(fit, condVar = TRUE)
chktol(names(re), rep("Subject", 2))

## confidence intervals
data("neck_pain", package = "ordinalCont")
fit <- ColrME(vas ~ laser * time + (1 | id), data = neck_pain,
              bounds = c(0, 1), support = c(0, 1))
ci <- confint(fit, pargroup = "shift", estimate = TRUE)
chktol(dim(ci), c(5, 3))
ci <- confint(fit, parm = "time2", pmatch = TRUE, type = "profile",
              parallel = "multicore", ncpus = 2)
chktol(dim(ci), c(2, 2))
ci <- confint(fit, "foo")
chktol(dim(ci), c(0, 2))

## logLik and LR test
library("ordinal")
fit1a <- PolrME(rating ~ temp + contact + (1 | judge), data = wine, method = "probit")
fit2a <- clmm2(rating ~ temp + contact, random = judge, data = wine,
               Hess = TRUE, nAGQ = 1, link = "probit")
chktol(logLik(fit1a), logLik(fit2a), tol = 1e-7)
fit1b <- PolrME(rating | contact ~ temp + (1 | judge), data = wine, method = "probit")
fit2b <- clmm2(rating ~ temp, nominal = ~ contact, random = judge, data = wine,
               Hess = TRUE, nAGQ = 1, link = "probit")
lrt1 <- anova(fit1a, fit1b)
lrt2 <- anova(fit2a, fit2b)
chktol(lrt1$Chisq[2], lrt2$`LR stat.`[2], tol = 1e-5)