package com.monpeya.backend.api.contracts;

import java.util.List;

public class SearchParam<T> {
    String operator;
    T start;
    T end;

    List<T> datas;

    public String getOperator() {
        return operator;
    }

    public void setOperator(String operator) {
        this.operator = operator;
    }

    public T getStart() {
        return start;
    }

    public void setStart(T start) {
        this.start = start;
    }

    public T getEnd() {
        return end;
    }

    public void setEnd(T end) {
        this.end = end;
    }

    public List<T> getDatas() {
        return datas;
    }

    public void setDatas(List<T> datas) {
        this.datas = datas;
    }
}
