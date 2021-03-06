context("Cube to tibble")

test_that("add_duplicate_suffix generates correct character vector", {
    expect_equal(
        add_duplicate_suffix(c("a", "a", "b", "c", "b", "c", "d")), 
        c("a_1", "a_2", "b_1", "c_1", "b_2", "c_2", "d")
    )
})

test_that("as_tibble on prop.table", {
    cube <- loadCube("cubes/cat-x-mr-x-mr.json")
    prop <- crunch::prop.table(cube, 1:2)
    expect_is(prop, "CrunchCubeCalculation")
    prop_tbl <- as_tibble(prop)
    expect_is(prop_tbl, "tbl_crunch_cube")
    expect_equal(
        names(prop_tbl), 
        c("animal", "opinion_mr_items", "feeling_mr_items", "proportion")
    )
    expect_equal(dim(prop_tbl), c(12, 4))
    expect_equal(prop[1,1,1], prop_tbl$proportion[1])
    expect_equal(prop[2,1,2], prop_tbl$proportion[8])
    
    expect_equal(
        attr(prop_tbl, "types"),
        structure(c("categorical", "subvariable_items", "subvariable_items", 
                    "measure"), .Names = c("animal", "opinion_mr", "feeling_mr", 
                                           "proportion"))
    )
    expect_is(attr(prop_tbl, "cube_metadata"), "list")
    expect_equal(length(attr(prop_tbl, "cube_metadata")), 4)
})

test_that("as_tibble on margin.table", {
    cube <- loadCube("cubes/cat-x-mr-x-mr.json")
    marg <- crunch::margin.table(cube, 1:2)
    expect_is(marg, "CrunchCubeCalculation")
    marg_tbl <- as_tibble(marg)
    expect_is(marg_tbl, "tbl_crunch_cube")
    expect_equal(
        names(marg_tbl), 
        c("animal", "opinion_mr_items", "feeling_mr_items", "margin")
    )
    expect_equal(dim(marg_tbl), c(12, 4))
    expect_equal(marg[1,1,1], marg_tbl$margin[1])
    expect_equal(marg[2,1,2], marg_tbl$margin[8])
    
    expect_equal(
        attr(marg_tbl, "types"),
        structure(c("categorical", "subvariable_items", "subvariable_items", 
                    "measure"), .Names = c("animal", "opinion_mr", "feeling_mr", 
                                           "margin"))
    )
    expect_is(attr(marg_tbl, "cube_metadata"), "list")
    expect_equal(length(attr(marg_tbl, "cube_metadata")), 4)
})

with_mock_crunch({
    ds <- loadDataset("test ds")
    ## Load a bunch of different cubes
    with_POST("https://app.crunch.io/api/datasets/1/multitables/apidocs-tabbook/", {
        book <- tabBook(multitables(ds)[[1]], data=ds)
    })

    test_that("Loading a bunch of different cube fixtures", {
        expect_is(book, "TabBookResult")
    })

    test_that("as_tibble method on a basic Cube", {
        cat_cat <- loadCube("cubes/cat-x-cat.json")
        cat_tibble <- as_tibble(cat_cat)
        expect_is(cat_tibble, "tbl_df")
        expect_equal(dim(cat_tibble), c(12, 5))
        expect_equal(names(cat_tibble), c("v4", "v7", "is_missing", "count", "row_count"))
        expect_equal(cat_tibble[cat_tibble$v4 == "B" & cat_tibble$v7 == "D", ]$count,
            3)
        expect_equal(cat_tibble$row_count, c(5, 5, 0, 3, 2, 0, 2, 3, 0, 0, 0, 0))
        expect_equal(cat_tibble$is_missing[1:5],c(FALSE, FALSE, TRUE, TRUE, TRUE))
    })

    test_that("as_tibble when repeated dimension vars", {
        tibble <- as_tibble(book[[2]][[3]])
        expect_is(tibble, "tbl_df")
        expect_equal(dim(tibble), c(25, 5))
        expect_equal(names(tibble)[1:2], c("q1_1", "q1_2"))
    })

    test_that("If weighted, the '.unweighted_counts' are included", {
        cube <- loadCube("cubes/feelings-pets-weighted.json")
        #check that cube has weights applied
        expect_false(all(cube@arrays$count == cube@arrays$.unweighted_counts))
        tibble <- as_tibble(cube)
        sub_tbl <- tibble[tibble$feelings == "extremely happy" & tibble$animals == "cats", ]
        expect_equal(sub_tbl$count, 119)
        expect_equal(sub_tbl$row_count, 9)
        expect_equal(tibble$count[c(2, 7, 15)], c(12, 5, 0))
        expect_equal(tibble$is_missing[5:10], c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE))
    })

    test_that("as_tibble on a cat_mr_mr cube", {
        cat_mr_mr <- loadCube("cubes/cat-x-mr-x-mr.json")
        cat_mr_mr_tibble <- as_tibble(cat_mr_mr)
        expect_is(cat_mr_mr_tibble, "tbl_df")

        expect_equal(dim(cat_mr_mr_tibble), c(162, 8))

        expect_equal(
            names(cat_mr_mr_tibble),
            c("animal", "opinion_mr_items", "opinion_mr_selections", "feeling_mr_items",
                "feeling_mr_selections", "is_missing", "count", "row_count"
            ))
    })


})
