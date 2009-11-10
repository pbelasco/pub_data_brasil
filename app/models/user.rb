class User < ActiveRecord::Base
  acts_as_authentic

  attr_accessor :role
  def role
    "admin"
  end
end
