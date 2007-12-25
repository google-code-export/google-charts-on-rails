class GoogleChart
  SERVER = 'http://chart.apis.google.com/chart?'.freeze
  TYPE_VAR = 'cht'.freeze
  SIZE_VAR = 'chs'.freeze
  DATA_VAR = 'chd'.freeze
  LABELS_VAR = 'chl'.freeze
  COLORS_VAR = 'chco'.freeze
  BAR_WIDTH_SPACING_VAR = 'chbh'.freeze
  TYPE_VAR_VALUES = {
    :line => 'lc',
    :line_xy => 'lxy',
    :bar_horizontal_stacked => 'bhs',
    :bar_vertical_stacked => 'bvs',
    :bar_horizontal_grouped => 'bhg',
    :bar_vertical_grouped => 'bhg',
    :pie => 'p',
    :pie_3d => 'p3',
    :venn => 'v',
    :scatter_plot => 's',
  }.freeze
  TYPE_MATCHING_REGEX = /#{TYPE_VAR_VALUES.keys.collect{|key|key.to_s} * '|'}/
  SIZE_MATCHING_REGEX = /([0-9]+)x([0-9]+)/
  DEFAULT_HEIGHT = 200
  DEFAULT_WIDTH = 200
  def self.method_missing(method, *args)
    protect_from_deep_stack do
      GoogleChart.new do |chart|
        chart.identifier(method, args)
      end
    end
  end
  def identifier(method, *args)
    method_to_match = method.to_s
    identify_type(method_to_match)
    identify_size(method_to_match)
    self.data = args
  end
  def respond_to?(method)
    #TODO: have to check with identifiers before returning true
    true 
  end

  def initialize()
    #set defaults
    @show_labels = true
    yield self if block_given?
  end
  attr_reader :type
  def type=(t)
    @type = t.to_sym
  end
  attr_accessor :colors
  attr_accessor :labels
  attr_accessor :data
  attr_accessor :height
  attr_accessor :width
  attr_accessor :show_labels
  #TODO: add support for bar width and spacing chbh=<bar width in pixels>,<optional space between groups>
  attr_accessor :bar_width
  attr_accessor :bar_spacing
  def to_url
    params = {}
    params[TYPE_VAR] = TYPE_VAR_VALUES[@type]
    params[SIZE_VAR] = "#{@height||DEFAULT_HEIGHT}x#{@width||DEFAULT_WIDTH}"
    params[DATA_VAR] = encode_data
    params[LABELS_VAR] = join_labels if (@labels && @show_labels)
    params[COLORS_VAR] = join(@colors) if (@colors)
    
    chart_params = []
    params.each_pair do |key, value|
      chart_params << "#{key}=#{value}"
    end
    "#{SERVER}#{(chart_params * '&amp;')}"
  end
  def to_img(options={})
    html_options = ''
    unless options.blank?
      options.each_pair{|key,value| html_options<<" #{key}='#{value}'"}
    end
    "<img src='#{to_url}'#{html_options}/>"
  end

protected
  def identify_type(source)
    self.type= source.match(TYPE_MATCHING_REGEX)[0]
  end
  def identify_size(source)
    matched = source.match(SIZE_MATCHING_REGEX) 
    if matched
      self.height = matched[1].to_i
      self.width = matched[2].to_i 
    end
  end
  def join(thingy)
    case thingy
      when String
        thingy
      when Array
        thingy * ','
    end
  end

  def join_labels
    @labels.collect{|l|CGI.escape(l)}.join('|')    
  end
  def data_encoding_type
    #TODO: identify the data type automatically after the data array is set
    @data_encoding_type || :text
  end
  def encode_data
    case data_encoding_type
      when :simple
        @encoded_data = simple_encode(@data)
      when :text
        @encoded_data = text_encode(@data)
      when :extended
        @encoded_data = extended_encode(@data)
    end
  end
  #encoding starts here
  SIMPLE_ENCODING_SOURCE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.freeze
  def simple_encode(data_to_encode)
    simple_encoding_size_minus_one = SIMPLE_ENCODING_SOURCE.size - 1
    max_value = data_to_encode.max
    encoded= 's:'
    data_to_encode.each do |current_value|
      #is there a better way of checking if an object is one of the numeric class
      if current_value.respond_to?(:integer?) && current_value >= 0
        encoded<<simpleEncoding[simple_encoding_size_minus_one * currentValue / max_value]
      else
        encoded<<'_'
      end
    end
    encoded
  end
  def text_encode(data_to_encode)
    #TODO:make sure all the data_to_encode is in the allowed range
    't:'+(data_to_encode * ',')
  end
  def extended_encode(data_to_encode)
    raise NotImplementedError.new('extended encoding of the data is not implemented')
  end
  #encoding ends here
  #utils start
  def self.logger
    RAILS_DEFAULT_LOGGER
  end
  def logger
    RAILS_DEFAULT_LOGGER
  end
  def self.protect_from_deep_stack
    return nil if @protection_from_deep_stack_is_set
    @protection_from_deep_stack_is_set = true
    whatever = yield if block_given?
    @protection_from_deep_stack_is_set = false
    whatever
  end
  #utils end
end