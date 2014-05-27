#= require thresholds/value_type
#= require thresholds/operator

onThresholds ->
  class @Condition
    constructor: (data) ->
      @field = ko.observable window.model.findField data?.field
      @compareField = ko.observable window.model.findField data?.compare_field ? data?.field # assign data.field only when data.compare_field doesn't exist to prevent error on view
      @op = ko.observable Operator.findByCode data?.op
      @value = ko.observable data?.value
      @valueType = ko.observable ValueType.findByCode data?.type ? 'value'
      @formattedValue = ko.computed =>
        switch @field()?.kind()
          when 'numeric' then "#{@valueType()?.format @value()}"
          else @field()?.format @value()
      @error = ko.computed => return "value is missing" unless @value()? and !!@value()
      @valid = ko.computed => not @error()?

      @field.subscribe =>
        @op Operator.EQ
        @compareField null
        @valueType ValueType.VALUE
        @value null

    toJSON: =>
      field: @field().esCode()
      op: @op().code()
      value: @value()
      type: @valueType().code()
      compare_field: @compareField()?.esCode()
