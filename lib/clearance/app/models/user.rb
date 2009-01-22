require 'digest/sha2'

module Clearance
  module App
    module Models
      module User
    
        def self.included(model)
          model.class_eval do
        
            attr_accessible :email, :password, :password_confirmation
            attr_accessor :password, :password_confirmation

            validates_presence_of     :email
            validates_length_of       :password, :if => :password_required?, :minimum => 6
            validates_confirmation_of :password, :if => :password_required?
            validates_uniqueness_of   :email, :case_sensitive => false
            validates_format_of       :email, :with => %r{.+@.+\..+}

            before_save :initialize_salt, :encrypt_password, :initialize_token, :downcase_email
        
            def self.authenticate(email, password)
              user = find(:first, :conditions => ['LOWER(email) = ?', email.to_s.downcase])
              user && user.authenticated?(password) ? user : nil
            end

            def authenticated?(password)
              encrypted_password == encrypt(password)
            end

            def encrypt(string)
              hash("--#{salt}--#{string}--")
            end

            def remember?
              token_expires_at && Time.now.utc < token_expires_at
            end

            def remember_me!
              remember_me_until 2.weeks.from_now.utc
            end

            def remember_me_until(time)
              self.update_attribute :token_expires_at, time
              self.update_attribute :token, 
                encrypt("--#{token_expires_at}--#{password}--")
            end

            def forget_me!
              self.update_attribute :token_expires_at, nil
              self.update_attribute :token, nil
            end

            def confirm_email!
              self.update_attribute :email_confirmed, true
              self.update_attribute :token, nil
            end
        
            protected
            
            def hash(string)
              Digest::SHA512.hexdigest(string)
            end

            def initialize_salt
              if new_record?
                self.salt = hash("--#{Time.now.utc.to_s}--#{password}--")
              end
            end

            def encrypt_password
              return if password.blank?
              self.encrypted_password = encrypt(password)
            end
            
            def initialize_token
              if new_record?
                self.token = encrypt("--#{Time.now.utc.to_s}--#{password}--")
              end
            end

            def password_required?
              encrypted_password.blank? || !password.blank?
            end
            
            def downcase_email
              self.email = email.to_s.downcase
            end
        
          end
        end
  
      end
    end
  end
end
