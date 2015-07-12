require 'logging'
require 'yaml/store'

# Autosign::Journal checks for one-time keys that have been used before

module Autosign
  class Journal
    attr_accessor :settings
    def initialize(settings = {})
      @log = Logging.logger['Autosign::Journal']
      @log.debug "initializing Autosign::Journal"
      @settings = settings
      fail unless self.setup
    end

    def setup
      journalfile = self.settings['journalfile']
      store = YAML::Store.new(journalfile, true)
      store.ultra_safe = true
      return store
    end

    # Check whether a UUID already exists in the journal
    #
    # ==== Attributes
    #
    # * +uuid+ - Unique journal entry identifier
    #
    # ==== Examples
    #
    # To exit if a token has already been used:
    #
    #    journal = Autosign::Journal.new({journalfile = '/etc/autosign/journal')
    #    exit 1 if journal.check('d2e601c8-93df-4459-be18-1877eaf00920')
    def check(uuid)
      fail unless validate_uuid(uuid)
      true
    end

    def delete(uuid)
      fail unless validate_uuid(uuid)
      true
    end


    # Add a new token to the journal
    #
    # ==== Attributes
    #
    # * +uuid+ - Unique journal entry identifier
    # * +validto+ - Integer seconds unix timestamp that the token will be valid until
    # * +data+ - Arbitrary hash that will be serialized and stored in the journal for auditing purposes
    #
    # ==== Examples
    #
    # To attempt adding a token to the journal:
    #
    #    journal = Autosign::Journal.new({journalfile = '/etc/autosign/journal')
    #    exit 1 if journal.add('d2e601c8-93df-4459-be18-1877eaf00920')
    #
    # This will only succeed if the token has not previously been added
    # This is the primary way this class is expected to be used
    def add(uuid, validto, data = {})
      @log.debug "attempting to add UUID: '#{uuid.to_s}' which is valid to '#{Time.at(validto.to_i)}' with data #{data.to_s}"
      puts validate_uuid(uuid).to_s
      #fail unless validate_uuid(uuid)
      #fail unless validate_timestamp(validto)
      #fail unless validate_data(data)

      store = self.setup
      # wrap the change in a transaction because multiple autosign instances
      # may try to run simultaneously. This will block until another process
      # releases the transaction lock.
      result = store.transaction do
        # check whether the UUID is already in the store
        if store.root?(uuid)
          @log.warn "Token with UUID '#{uuid}' is already saved in the journal, will not add'"
          store.abort
        else
          # save the token identified by UUID
          store[uuid.to_s] = {:validto => validto.to_s, :data => data}
        end
      end

      # return true if the transaction went through
      return !!result
    end

    def validate_uuid(uuid)
      unless uuid.is_a?(String)
        @log.error "UUID is not a string"
        return false
      end

      unless !!/^\S{8}-\S{4}-4\S{3}-[89abAB]\S{3}-\S{12}$/.match(uuid.to_s)
        @log.error "UUID is not a valid V4 UUID"
        return false
      end
    end

    def validate_data(data)
      unless data.is_a?(Hash)
        @log.error "data is not a hash"
        return false
      end
    end

    def validate_timestamp(time)
      unless time.is_a?(Integer)
        @log.error "timestamp is not an integer"
        return false
      end

      if Time.at(time) > Time.now
        @log.debug "validated timestamp: " + time
        return true
      else
        @log.error "invalid timestamp: " + time
        return false
      end
    end
  end
end
