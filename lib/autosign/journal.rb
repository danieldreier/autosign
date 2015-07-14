require 'logging'
require 'yaml/store'


module Autosign
# Autosign::Journal tracks one-time keys to prevent key re-use.
# Keys are stored in the journal file by UUID.
# The journal uses ruby's yaml/store, which is a YAML version of the PStore
# data store. It is multi-process safe, and blocks until transactions in other
# processes are complete.
  class Journal
    #@return [Hash] settings of the autosign journal instance, such as the location of the journal file
    attr_accessor :settings

    # @param settings [Hash] config settings for the new journal instance
    # @return [Autosign::Journal] instance of the Autosign::Journal class
    def initialize(settings = {})
      @log = Logging.logger['Autosign::Journal']
      @log.debug "initializing Autosign::Journal"
      @settings = settings
      fail unless setup
    end



    # Add a new token to the journal. Only succeeds if the token is not in the journal already.
    #
    # @param uuid [String] RFC4122 v4 UUID functioning as unique journal entry identifier
    # @param validto [Integer] POSIX timestamp in seconds since epoch that the token will be valid until
    # @param data [Hash] Arbitrary hash that will be serialized and stored in the journal for auditing purposes
    #
    # @example attempt adding a token to the journal
    #   journal = Autosign::Journal.new({journalfile = '/etc/autosign/journal')
    #   fail unless journal.add('d2e601c8-93df-4459-be18-1877eaf00920')
    #
    # This will only succeed if the token has not previously been added
    # This is the primary way this class is expected to be used
    def add(uuid, validto, data = {})
      @log.debug "attempting to add UUID: '#{uuid.to_s}' which is valid to '#{Time.at(validto.to_i)}' with data #{data.to_s}"
      return false unless validate_uuid(uuid)

      store = setup
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

    private

    # Create a new journal file, or load an existing one if it already exists.
    # @return [YAML::Store] instance of YAML::Store using the configured journal file.
    def setup
      @log.debug "using journalfile: " + self.settings['journalfile']
      journalfile = self.settings['journalfile']
      store = YAML::Store.new(journalfile, true)
      store.ultra_safe = true
      return store
    end

    # Verify that a string is a V4 UUID
    #
    # @param uuid [String] RFC4122 v4 UUID
    # @return [Boolean] true if the uuid string is a valid UUID, false if not a valid UUID
    def validate_uuid(uuid)
      unless uuid.is_a?(String)
        @log.error "UUID is not a string"
        return false
      end

      unless !!/^\S{8}-\S{4}-4\S{3}-[89abAB]\S{3}-\S{12}$/.match(uuid.to_s)
        @log.error "UUID is not a valid V4 UUID"
        return false
      end
      return true
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
