package com.djogana.ticketing.api.contracts;

import java.util.HashMap;
import java.util.List;

/**
 * @author geovani.anoman
 */
public class CriteriaUtils {

    final static String START_SUFFIX = "_start";
    final static String END_SUFFIX = "_end";

    /**
     * @param listOfQuery : list of query
     * @return String : criteria
     */
    public static String getCriteriaByListOfQuery(List<String> listOfQuery) {
        StringBuilder query = new StringBuilder();
        if (!listOfQuery.isEmpty()) {
            for (String q : listOfQuery) {
                query.append(q);
                if (!listOfQuery.get(listOfQuery.size() - 1).equals(q)) {
                    query.append(" and ");
                }
            }
        }
        return query.toString();
    }

    /**
     * @param fieldName     : name of the field
     * @param fieldValue    : value of the field
     * @param jpqlFieldName : name of the field in the jpql query
     * @param fieldType     : type of the field
     * @param fieldParam    : parameter of the field
     * @param params        : list of parameters
     * @return String : criteria
     */
    public static <T> String generateCriteria(String fieldName, Object fieldValue, String jpqlFieldName, String fieldType, SearchParam<T> fieldParam, HashMap<String, Object> params, Integer index) {
        String req = "";
        String operator = "";
        T start = null;
        T end = null;

        if (fieldParam != null) {
            operator = fieldParam.getOperator();
            start = fieldParam.getStart();
            end = fieldParam.getEnd();
        }
        fieldName += "_" + index;


        switch (fieldType) {
            case "String":
                switch (operator) {
                    case OperatorEnum.NOT_EQUAL_1:
                    case OperatorEnum.NOT_EQUAL_2:
                        req += String.format(" %1$s <> :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.EQUAL:
                        req += String.format(" %1$s = :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.START_WTIH:
                        req += String.format(" %1$s LIKE :%2$s ", jpqlFieldName, fieldName);
                        fieldValue = fieldValue + "%";
                        break;
                    case OperatorEnum.END_WTIH:
                        req += String.format(" %1$s LIKE :%2$s ", jpqlFieldName, fieldName);
                        fieldValue = "%" + fieldValue;
                        break;
                    default:
                        req += String.format(" %1$s LIKE :%2$s ", jpqlFieldName, fieldName);
                        fieldValue = "%" + fieldValue + "%";
                        break;
                }
                break;
            case "Integer":
            case "Long":
            case "Double":
            case "Decimal":
            case "BigDecimal":
            case "BigInteger":
            case "Float":
                switch (operator) {
                    case OperatorEnum.NOT_EQUAL_1:
                    case OperatorEnum.NOT_EQUAL_2:
                        req += String.format(" %1$s <> :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.LESS:
                        req += String.format(" %1$s < :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.LESS_OR_EQUAL:
                        req += String.format(" %1$s <= :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.MORE:
                        req += String.format(" %1$s > :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.MORE_OR_EQUAL:
                        req += String.format(" %1$s >= :%2$s ", jpqlFieldName, fieldName);
                        break;
                    case OperatorEnum.BETWEEN:
                        params.put(fieldName + START_SUFFIX, start);
                        params.put(fieldName + END_SUFFIX, end);
                        req += String.format(" %1$s >= :%2$s and %1$s <= :%3$s ", jpqlFieldName, fieldName + START_SUFFIX, fieldName + END_SUFFIX);
                        break;
                    case OperatorEnum.BETWEEN_OUT:
                        params.put(fieldName + START_SUFFIX, start);
                        params.put(fieldName + END_SUFFIX, end);
                        req += String.format(" %1$s > :%2$s and %1$s < :%3$s ", jpqlFieldName, fieldName + START_SUFFIX, fieldName + END_SUFFIX);
                        break;
                    case OperatorEnum.BETWEEN_LEFT_OUT:
                        params.put(fieldName + START_SUFFIX, start);
                        params.put(fieldName + END_SUFFIX, end);
                        req += String.format(" %1$s > :%2$s and %1$s <= :%3$s ", jpqlFieldName, fieldName + START_SUFFIX, fieldName + END_SUFFIX);
                        break;
                    case OperatorEnum.BETWEEN_RIGHT_OUT:
                        params.put(fieldName + START_SUFFIX, start);
                        params.put(fieldName + END_SUFFIX, end);
                        req += String.format(" %1$s >= :%2$s and %1$s < :%3$s ", jpqlFieldName, fieldName + START_SUFFIX, fieldName + END_SUFFIX);
                        break;
                    default:
                        req += String.format(" %1$s = :%2$s ", jpqlFieldName, fieldName);
                        break;
                }
                break;
            case "Date":
                switch (operator) {
                    case OperatorEnum.NOT_EQUAL_1:
                    case OperatorEnum.NOT_EQUAL_2:
                        req += String.format(" %1$s <> TO_DATE('%2$s' ,'DD/MM/YYYY') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.LESS:
                        req += String.format(" %1$s < TO_DATE('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue + " 23:59:59");
                        break;
                    case OperatorEnum.LESS_OR_EQUAL:
                        req += String.format(" %1$s <= TO_DATE('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue + " 23:59:59");
                        break;
                    case OperatorEnum.MORE:
                        req += String.format(" %1$s > TO_DATE('%2$s' ,'DD/MM/YYYY') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.MORE_OR_EQUAL:
                        req += String.format(" %1$s >= TO_DATE('%2$s' ,'DD/MM/YYYY') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.BETWEEN:
                        req += String.format(" %1$s >= TO_DATE('%2$s' ,'DD/MM/YYYY HH24:MI:SS') and %1$s <= TO_DATE('%3$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, start, end);
                        break;
                    case OperatorEnum.BETWEEN_OUT:
                        req += String.format(" %1$s > TO_DATE('%2$s' ,'DD/MM/YYYY') and %1$s < TO_DATE('%3$s' ,'DD/MM/YYYY') ", jpqlFieldName, start, end);
                        break;
                    case OperatorEnum.BETWEEN_LEFT_OUT:
                        req += String.format(" %1$s > TO_DATE('%2$s' ,'DD/MM/YYYY') and %1$s <= TO_DATE('%3$s' ,'DD/MM/YYYY') ", jpqlFieldName, start, end);
                        break;
                    case OperatorEnum.BETWEEN_RIGHT_OUT:
                        req += String.format(" %1$s >= TO_DATE('%2$s' ,'DD/MM/YYYY') and %1$s < TO_DATE('%3$s' ,'DD/MM/YYYY') ", jpqlFieldName, start, end);
                        break;
                    default:
                        req += String.format(" %1$s = TO_DATE('%2$s' ,'DD/MM/YYYY') ", jpqlFieldName, fieldValue);
                        //req += String.format(" TO_DATE( %1$s ,'DD/MM/YYYY') = TO_DATE('%2$s' ,'DD/MM/YYYY') ", jpqlFieldName, fieldValue);
                        break;
                }
                break;

            case "Timestamp":
                switch (operator) {
                    case OperatorEnum.NOT_EQUAL_1:
                    case OperatorEnum.NOT_EQUAL_2:
                        req += String.format(" %1$s <> TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.LESS:
                        req += String.format(" %1$s < TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.LESS_OR_EQUAL:
                        req += String.format(" %1$s <= TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.MORE:
                        req += String.format(" %1$s > TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.MORE_OR_EQUAL:
                        req += String.format(" %1$s >= TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue);
                        break;
                    case OperatorEnum.BETWEEN:
                        req += String.format(" %1$s >= TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') and %1$s <= TO_TIMESTAMP('%3$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, start, end);
                        break;
                    case OperatorEnum.BETWEEN_OUT:
                        req += String.format(" %1$s > TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') and %1$s < TO_TIMESTAMP('%3$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, start, end);
                        break;
                    case OperatorEnum.BETWEEN_LEFT_OUT:
                        req += String.format(" %1$s > TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') and %1$s <= TO_TIMESTAMP('%3$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, start, end);
                        break;
                    case OperatorEnum.BETWEEN_RIGHT_OUT:
                        req += String.format(" %1$s >= TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') and %1$s < TO_TIMESTAMP('%3$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, start, end);
                        break;
                    default:
                        req += String.format(" %1$s = TO_TIMESTAMP('%2$s' ,'DD/MM/YYYY HH24:MI:SS') ", jpqlFieldName, fieldValue);
                        break;
                }
                break;
            case "Boolean":
                switch (operator) {
                    case OperatorEnum.NOT_EQUAL_1:
                    case OperatorEnum.NOT_EQUAL_2:
                        req += jpqlFieldName + " <> :" + fieldName;
                        break;
                    default:
                        req += jpqlFieldName + " = :" + fieldName;
                        break;
                }
                break;
        }
//		if (!OperatorEnum.IS_BETWEEN_OPERATOR(operator) && "Date".equals(fieldType)) {
//			fieldValue = new SimpleDateFormat("dd/MM/yyyy").parse(fieldValue.toString());
//		}
        if (!OperatorEnum.IS_BETWEEN_OPERATOR(operator)) {
            if (!("Date".equals(fieldType))) {
                params.put(fieldName, fieldValue);
            }
        }

        return req;
    }
}