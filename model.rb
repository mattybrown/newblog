require "data_mapper"
require "dm-sqlite-adapter"
require "bcrypt"
require "tilt/erb"
#require 'carrierwave'
require 'carrierwave/datamapper'

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db.sqlite")

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads"
  end

  def extensions_white_list
    %w(jpg jpeg gif png)
  end

  process :resize_to_limit => [700,700]
  version :thumb do
    process :resize_to_fill => [200,200]
  end
end


class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, :key => true
  property :username, String, :length => 3..50
  property :password, BCryptHash

  def authenticate(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
end

class Story
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :title, String
  property :body, Text
  property :summary, Text

  mount_uploader :file, ImageUploader

end

DataMapper.finalize
DataMapper.auto_upgrade!
