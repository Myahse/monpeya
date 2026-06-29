package com.djogana.ticketing.api.contracts;

import java.util.Arrays;
import java.util.List;

public class OperatorEnum {
    public static final String  EQUAL        = "=";
    public static final String  NOT_EQUAL_1      = "<>";
    public static final String  NOT_EQUAL_2      = "!=";
    public static final String  LESS_OR_EQUAL    = "<=";
    public static final String  LESS        = "<";
    public static final String  MORE_OR_EQUAL    = ">=";
    public static final String  MORE        = ">";
    public static final String  BETWEEN        = "[]";
    public static final String  BETWEEN_OUT      = "][";
    public static final String  BETWEEN_LEFT_OUT  = "]]";
    public static final String  BETWEEN_RIGHT_OUT  = "[[";
    public static final String  CONTAINS      = "%%";
    public static final String  START_WTIH      = "_%";
    public static final String  END_WTIH      = "%_";

    public static final String  IN          = "IN";
    public static final String  NOT_IN        = "!IN";
    public static final String  EXISTS        = "EXISTS";
    public static final String  NOT_EXISTS      = "!EXISTS";

    private static final List<String> LIST_OF_ALL_OPERATORS = Arrays.asList(EQUAL, NOT_EQUAL_1, NOT_EQUAL_2, LESS_OR_EQUAL, LESS, MORE_OR_EQUAL, MORE, BETWEEN, BETWEEN_OUT, BETWEEN_LEFT_OUT, BETWEEN_RIGHT_OUT, CONTAINS, START_WTIH, END_WTIH, IN, NOT_IN, EXISTS, NOT_EXISTS);

    private static final List<String> LIST_OF_BETWEEN = Arrays.asList(BETWEEN, BETWEEN_OUT, BETWEEN_LEFT_OUT, BETWEEN_RIGHT_OUT);
    private static final List<String> LIST_OF_IN = Arrays.asList(IN, NOT_IN);
    private static final List<String> LIST_OF_OPERATORS_NEEDING_FIELD_VALUE = Arrays.asList(EQUAL, NOT_EQUAL_1, NOT_EQUAL_2, LESS_OR_EQUAL, LESS, MORE_OR_EQUAL, MORE, CONTAINS, START_WTIH, END_WTIH);
    private static final List<String> LIST_OF_OPERATORS_NOT_NEEDING_ANY_VALUES = Arrays.asList(EXISTS, NOT_EXISTS);


    public static final boolean  IS_VALID_OPERATOR (String operator){
        return LIST_OF_ALL_OPERATORS.stream().anyMatch(s -> operator.equals(s));
    }

    public static final boolean  IS_BETWEEN_OPERATOR (String operator){
        return LIST_OF_BETWEEN.stream().anyMatch(s -> operator.equals(s));
    }

    public static final boolean  IS_IN_OPERATOR (String operator){
        return LIST_OF_IN.stream().anyMatch(s -> operator.equals(s));
    }

    public static final boolean  OPERATOR_NEEDS_FIELD_VALUE (String operator){
        return LIST_OF_OPERATORS_NEEDING_FIELD_VALUE.stream().anyMatch(s -> operator.equals(s));
    }

    public static final boolean  OPERATOR_NOT_NEEDS_ANY_VALUE (String operator){
        return LIST_OF_OPERATORS_NOT_NEEDING_ANY_VALUES.stream().anyMatch(s -> operator.equals(s));
    }
}
