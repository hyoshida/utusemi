module Utusemi
  class Railtie < ::Rails::Railtie
    initializer 'utusemi.initializer' do
      Utusemi.enable
    end
  end
end
