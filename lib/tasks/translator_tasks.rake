namespace :translator do

  desc "Generate yml files for chosen locale ex. Locale='en' defined in Translator, with Options 'all', 'framework' "
  task :dump_locale => :environment do
    options = ENV['Options']
    locale = ENV['Locale']
    if locale
      path = File.join( RAILS_ROOT, "/config/locales/dump/")
      begin
        system( mkdir "#{path}")
      rescue
        # folder dump already exists
      end
      write(path + "#{options ? options : 'application'}.#{locale}.yml ", Translator.translation_hash_for_locale("#{locale}", "#{options}"))
    else
      puts "Please chose locale to dump ex. Locale='en' "
    end
  end
  
  task :dump_all => :environment do
    path = File.join( RAILS_ROOT, "/config/locales/dump/")
    if Translator.chosen_locales
      
      Translator.chosen_locales.each do |locale|
       write(path + "application.#{locale}.yml ", Translator.translation_hash_for_locale("#{locale}", ""))
       write(path + "framework.#{locale}.yml ", Translator.translation_hash_for_locale("#{locale}", "framework"))
      end
    else
      Translator.available_locales.each do |locale|
       write(path + "application.#{locale}.yml ", Translator.translation_hash_for_locale("#{locale}", ""))
       write(path + "framework.#{locale}.yml ", Translator.translation_hash_for_locale("#{locale}", "framework"))
      end
    end
  end
  
end

def write(filename, hash)
  File.open(filename, "w") do |f|
    f.write(hash.ya2yaml)
  end
end