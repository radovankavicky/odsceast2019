library(useful)
library(coefplot)
library(glmnet)
library(recipes)
library(parsnip)

house_train <- readr::read_rds(
    'data/manhattan_Train.rds'
)

names(house_train)

house_formula <- TotalValue ~ FireService + 
    ZoneDist1 + ZoneDist2 + 
    Class + LandUse + OwnerType + LotArea + 
    BldgArea + ComArea + ResArea + OfficeArea + 
    RetailArea + NumBldgs + NumFloors + 
    UnitsRes + UnitsTotal + 
    LotFront + LotDepth + BldgFront + Landmark + 
    BuiltFAR + 
    HistoricDistrict + Built

class(house_formula)

house1 <- lm(house_formula, data=house_train)
summary(house1)
coefplot(house1, sort='magnitude')

?glmnet

recipe(
    house_formula, 
    data=house_train
)


ny <- tibble::tribble(
    ~ Boro, ~ Pop, ~ Area, ~ Random,
    'Manhattan', 1700000, 23, 17,
    'Queens', 2600000, 104, 42,
    'Bronx', 1200000, 42, 3,
    'Staten Island', 475000, 66, 1/2,
    'Brooklyn', 2400000, 79, pi
)
ny

lm(Random ~ Pop, data=ny)

build.x(Random ~ Pop, data=ny)

lm(Random ~ Pop + Area, data=ny)
build.x(Random ~ Pop + Area, data=ny)
build.x(Random ~ Pop * Area, data=ny)
build.x(Random ~ Pop*Area - Pop - Area, ny)
build.x(Random ~ Pop:Area,ny)

build.x(Random ~ Boro, data=ny)
build.x(Random ~ Boro, 
        data=ny,
        contrasts=FALSE)

build.x(Random ~ scale(Pop) + scale(Area), ny)
build.x(Random ~ scale(Pop) + scale(Area), 
        ny) %>% 
    colMeans()
build.x(Random ~ log(Pop), ny)

recipe(
    Random ~ Pop + Area + Boro, 
    data=ny
) %>% 
    prep() %>% 
    juice()

basic_rec <- recipe(
    Random ~ Pop + Area + Boro, 
    data=ny
)
basic_rec

basic_rec %>% 
    step_dummy(Boro) %>% 
    prep() %>% 
    juice()

basic_rec %>%
    step_center(Pop, Area) %>% 
    step_scale(Pop, Area) %>% 
    step_dummy(
        Boro, 
        one_hot=FALSE) %>% 
    prep() %>% 
    juice()

boro_recipe <- basic_rec %>%
    step_center(Pop, Area) %>% 
    step_scale(Pop, Area) %>% 
    step_dummy(
        Boro, 
        one_hot=TRUE
    ) %>% 
    step_intercept()
boro_recipe
boro_prepped <- boro_recipe %>% 
    prep()
boro_prepped

boro_prepped %>% 
    juice(Random)

boro_prepped %>% 
    juice(
        all_predictors(),
        composition='dgCMatrix'
    )

boro_prepped %>% 
    juice(
        all_outcomes(),
        composition='matrix'
    )


house_rec <- recipe(
    house_formula,
    data=house_train
) %>% 
    step_log(TotalValue) %>% 
    step_other(
        all_nominal(), 
        threshold=0.1
    ) %>% 
    step_dummy(
        all_nominal(),
        one_hot=TRUE
    )
house_rec
house_prepped <- house_rec %>% 
    prep()
house_prepped

house_x <- house_prepped %>% 
    juice(
        all_predictors(),
        composition='dgCMatrix'
    )

house_y <- house_prepped %>% 
    juice(
        all_outcomes(),
        composition='matrix'
    )

dim(house_x)
dim(house_y)

house2 <- glmnet(x=house_x, y=house_y,
                 family='gaussian'
)
plot(house2)
plot(house2, xvar='lambda')
plot(house2, xvar='lambda', label=TRUE)
coefpath(house2)

library(animation)
cv.ani(k=5)

house3 <- cv.glmnet(
    x=house_x, y=house_y,
    family='gaussian',
    nfolds=5
)
readr::write_rds(house3, 'app/house3.rds')
plot(house3)

class(house2)
class(house3)

coefpath(house3)
coefplot(house3, sort='magnitude', 
         lambda='lambda.min')

coefplot(house3, sort='magnitude', 
         lambda='lambda.1se', intercept=FALSE)

house4 <- cv.glmnet(
    x=house_x, y=house_y,
    family='gaussian',
    nfolds=5,
    alpha=0
)
coefpath(house4)
plot(house4)

house5 <- cv.glmnet(
    x=house_x, y=house_y,
    family='gaussian',
    nfolds=5,
    alpha=0.4
)
coefpath(house5)

house_test <- readr::read_rds(
    'data/manhattan_Test.rds'
)

house_new_x <- house_prepped %>% 
    bake(all_predictors(), new_data=house_test,
         composition='dgCMatrix')
readr::write_rds(house_new_x, 'app/house_new.rds')
house_preds <- predict(
    house5, newx=house_new_x,
    s='lambda.1se'
)
head(house_preds) %>% exp()
house_preds %>% head() %>% exp()
exp(head(house_preds))
house5$glmnet.fit

house6 <- linear_reg() %>% 
    parsnip::set_engine(engine='glmnet') %>% 
    fit_xy(x=as.matrix(house_x), y=house_y)

house6$fit %>% coefpath()
house6$spec

house7 <- linear_reg() %>% 
    parsnip::set_engine(engine='lm') %>% 
    fit_xy(x=as.matrix(house_x), y=house_y)
house7$fit %>% coefplot
