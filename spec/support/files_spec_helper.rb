require 'spec_helper'

module FilesSpecHelper

  def create_file(file_format, str)
    path_to_file =  File.expand_path "~/" "bulk_data_methods_temp_file.#{file_format}"
    File.open(path_to_file, 'w') do |file|
      file.write str
    end

    path_to_file
  end

  def delete_file(path_to_file)
    File.delete(path_to_file)
  end

end