class Rule < ActiveRecord::Base
  attr_accessible :code, :description, :name, :rule_code, :sequence
end
