#= require thresholds/operator
#= require thresholds/option
onThresholds ->
  class @Field
    constructor: (data) ->
      @esCode = ko.observable "#{data.id}"
      @name = ko.observable data.name
      @code = ko.observable data.code
      @kind = ko.observable data.kind
      @config = data?.config

      @impl = new window["Field_#{@kind()}"](@)
      @options = ko.computed => @impl.getOptions() 
      @operators = ko.computed => @impl.getOperators()
      @value = ko.observable()

      @buildFieldHierarchyItems() if @kind() == 'hierarchy'

    format: (value) ->
      @impl.format value

    findOptionById: (optionId) ->
      return option for option in @options() when option.id() == optionId

    encode: (value) ->
      @impl.encode value

    valid: (value) ->
      @impl.valid value

    buildFieldHierarchyItems: () ->
      @hierarchy = @config.hierarchy
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: window.t('javascripts.collections.fields.no_value')})   

  class @FieldImpl
    constructor: (field) ->
      @field = field

    format: (value) ->
      value
    getOptions: => []
    getOperators: => [Operator.EQ]
    encode: (value) -> value
    valid: (value) -> !!value

  class @Field_hierarchy extends @FieldImpl
    format: (value) ->
      @hierarchy = @field.config.hierarchy
      matches = getLabelFromId(@hierarchy, value, [])
      if matches.length > 0
        matches[0]

    getLabelFromId = (hierarchy, value, matches) ->
      for h in hierarchy
        if parseInt(h.id) == parseInt(value)
          matches.push(h.name)
          break
        if h.sub
          getLabelFromId(h.sub, value, matches)  
      return matches

    getOperators: =>
      [Operator.UNDER]

    encode: (value) =>
      value

    valid: (value) =>
      value

  class @FieldText extends @FieldImpl
    getOperators: =>
      [Operator.EQI, Operator.CON]

  class @Field_text extends @FieldText

  class @Field_numeric extends @FieldImpl
    getOperators: =>
      [Operator.EQ, Operator.LT, Operator.GT]

    valid: (value) ->
      value? and
      value.toString().trim().length > 0 and
      not isNaN value

  class @Field_yes_no extends @FieldImpl
    format: (value) ->
      if value then 'Yes' else 'No'

    getOptions: =>
      [new Option({id: true, label: 'Yes'}), new Option({id: false, label: 'No'})]

    valid: (value) ->
      if typeof(value) == 'boolean'
        true
      else
        false
      
  class @FieldSelectOne extends @FieldImpl
    format: (value) ->
      @field.findOptionById(value)?.label()

    getOptions: =>
      $.map @field.config?.options ? [], (option) -> new Option option

  class @Field_date extends @FieldImpl
    format: (value) ->
      value?.toString().toDate()?.strftime '%m/%d/%Y'

    getOperators: =>
      [Operator.EQ, Operator.LT, Operator.GT]

    encode: (value) ->
      value?.toString().toDate()?.strftime '%m/%d/%Y'

    valid: (value) ->
      !!value


  class @Field_email extends @FieldText

  class @Field_phone extends @FieldText

  class @Field_select_many extends @FieldSelectOne
    format: (value) ->
      if value instanceof Array  
        @field.findOptionById(value[0])?.label()
      else
        @field.findOptionById(value)?.label()

    encode: (value) ->
      if value instanceof Array ? 
        value
      else
        [value]

  class @Field_select_one extends @FieldSelectOne












