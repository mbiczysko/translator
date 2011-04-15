require 'translator/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3

module Translator
  class << self
    attr_accessor :auth_handler, :current_store, :framework_keys, :chosen_locales
    attr_reader :simple_backend
    attr_writer :layout_name
  end

  @framework_keys = ["date.formats.default", "date.formats.short", "date.formats.long", "date.day_names", "date.abbr_day_names", "date.month_names",
                     "date.abbr_month_names", "date.order",
                     "time.formats.default", "time.formats.short", "time.formats.long", "time.am", "time.pm", 
                     "support.array.words_connector", "support.array.two_words_connector", "support.array.last_word_connector", 
                     "errors.format", "errors.messages.inclusion", "errors.messages.exclusion", "errors.messages.invalid", 
                     "errors.messages.confirmation", "errors.messages.accepted", "errors.messages.empty", 
                     "errors.messages.blank", "errors.messages.too_long", "errors.messages.too_short", "errors.messages.wrong_length", 
                     "errors.messages.not_a_number", "errors.messages.not_an_integer", "errors.messages.greater_than", 
                     "errors.messages.greater_than_or_equal_to", "errors.messages.equal_to", "errors.messages.less_than", 
                     "errors.messages.less_than_or_equal_to", "errors.messages.odd", "errors.messages.even", "errors.required", "errors.blank", 
                     "number.format.separator", "number.format.delimiter", "number.currency.format.format", "number.currency.format.unit", 
                     "number.currency.format.separator", "number.currency.format.delimiter", "number.percentage.format.delimiter", 
                     "number.precision.format.delimiter", "number.human.format.delimiter", "number.human.storage_units.format", 
                     "number.human.storage_units.units.byte.one", "number.human.storage_units.units.byte.other", 
                     "number.human.storage_units.units.kb", "number.human.storage_units.units.mb", "number.human.storage_units.units.gb", 
                     "number.human.storage_units.units.tb", "number.human.decimal_units.format", "number.human.decimal_units.units.unit", 
                     "number.human.decimal_units.units.thousand", "number.human.decimal_units.units.million", 
                     "number.human.decimal_units.units.billion", "number.human.decimal_units.units.trillion", 
                     "number.human.decimal_units.units.quadrillion", "datetime.distance_in_words.half_a_minute", 
                     "datetime.distance_in_words.less_than_x_seconds.one", "datetime.distance_in_words.less_than_x_seconds.other", 
                     "datetime.distance_in_words.x_seconds.one", "datetime.distance_in_words.x_seconds.other", 
                     "datetime.distance_in_words.less_than_x_minutes.one", "datetime.distance_in_words.less_than_x_minutes.other", 
                     "datetime.distance_in_words.x_minutes.one", "datetime.distance_in_words.x_minutes.other", 
                     "datetime.distance_in_words.about_x_hours.one", "datetime.distance_in_words.about_x_hours.other", 
                     "datetime.distance_in_words.x_days.one", "datetime.distance_in_words.x_days.other", 
                     "datetime.distance_in_words.about_x_months.one", "datetime.distance_in_words.about_x_months.other", 
                     "datetime.distance_in_words.x_months.one", "datetime.distance_in_words.x_months.other", 
                     "datetime.distance_in_words.about_x_years.one", "datetime.distance_in_words.about_x_years.other", 
                     "datetime.distance_in_words.over_x_years.one", "datetime.distance_in_words.over_x_years.other", 
                     "datetime.distance_in_words.almost_x_years.one", "datetime.distance_in_words.almost_x_years.other", 
                     "datetime.prompts.year", "datetime.prompts.month", "datetime.prompts.day", "datetime.prompts.hour", 
                     "datetime.prompts.minute", "datetime.prompts.second", "helpers.select.prompt", "helpers.submit.create", 
                     "helpers.submit.update", "helpers.submit.submit"]

  def self.setup_backend(simple_backend)
    @simple_backend = simple_backend

    I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(@current_store), @simple_backend)
  end

  def self.locales
    @simple_backend.available_locales
  end
  
  def self.chosen_locales
    @chosen_locales
  end

  def self.keys_for_strings(options = {})
    @simple_backend.available_locales

    flat_translations = {}
    flatten_keys nil, @simple_backend.instance_variable_get("@translations"), flat_translations
    flat_translations = flat_translations.delete_if {|k,v| !v.is_a?(String)}
    keys = (flat_translations.keys + 
            Translator.current_store.keys).map {|k| k.sub(/^\w*\./, '') }.uniq
    if options[:show].to_s == "all"
      keys
    elsif options[:show].to_s == "framework"
      keys.select {|k| @framework_keys.include?(k) }
    else
      keys - @framework_keys
    end
  end
  
  #returning hash for locale, with options "all", "framework"
  def self.translation_hash_for_locale(locale, options = "" )
    translation_hash_for_locale = {}
    self.keys_for_strings({ :show => options.to_s }).each do |key|
      begin
        translation_hash_for_locale.deep_merge!(Translator.unsquish("#{key}", I18n.backend.translate(locale.to_sym,"#{key}")))
      rescue 
        # translatiton missing
        translation_hash_for_locale.deep_merge!(Translator.unsquish("#{key}", ""))    
      end
    end
    { "#{locale}" => translation_hash_for_locale }
  end
  
  #Get all translation for simple_backend
  def self.simple_translations
    self.simple_backend.instance_variable_get("@translations")
  end
  
  
  
  #Get all the collection key_value_store
  def self.collection
    self.current_store.instance_variable_get("@collection")
  end
  
  #Get collection for chosen locale
  def self.locale_collection(locale)
    self.collection.find({"_id" =>/^#{locale.to_s.downcase}\./})
  end

  def self.layout_name
    @layout_name || "translator"
  end

  private

  def self.flatten_keys(current_key, hash, dest_hash)
    hash.each do |key, value|
      full_key = [current_key, key].compact.join('.')
      if value.kind_of?(Hash)
        flatten_keys full_key, value, dest_hash
      else
        dest_hash[full_key] = value
      end
    end
    hash
  end
  
  #use to create hash from key value string
  def self.unsquish(string, value)
    if string.is_a?(String)
      unsquish(string.split("."), value)
    elsif string.size == 1
      { string.first => value }
    else
      key  = string[0]
      rest = string[1..-1]
      { key => unsquish(rest, value) }
    end
  end
  
end

