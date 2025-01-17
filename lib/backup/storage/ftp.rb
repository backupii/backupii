# frozen_string_literal: true

require "net/ftp"

module Backup
  module Storage
    class FTP < Base
      include Storage::Cycler

      ##
      # Server credentials
      attr_accessor :username, :password

      ##
      # Server IP Address and FTP port
      attr_accessor :ip, :port

      ##
      # Use passive mode?
      attr_accessor :passive_mode

      ##
      # Configure connection open and read timeouts.
      # Net::FTP's open_timeout and read_timeout will both be configured using
      # this setting.
      # @!attribute [rw] timeout
      #   @param [Integer|Float]
      #   @return [Integer|Float]
      attr_accessor :timeout

      def initialize(model, storage_id = nil)
        super

        @port         ||= 21
        @path         ||= "backups".dup
        @passive_mode ||= false
        @timeout      ||= nil
        path.sub!(%r{^~/}, "")
      end

      private

      ##
      # Establishes a connection to the remote server
      #
      # Note:
      # Since the FTP port is defined as a constant in the Net::FTP class, and
      # might be required to change by the user, we dynamically remove and
      # re-add the constant with the provided port value
      def connection
        if Net::FTP.const_defined?(:FTP_PORT)
          Net::FTP.send(:remove_const, :FTP_PORT)
        end; Net::FTP.send(:const_set, :FTP_PORT, port)

        # Ensure default passive mode to false.
        # Note: The default passive setting changed between Ruby 2.2 and 2.3
        if Net::FTP.respond_to?(:default_passive=)
          Net::FTP.default_passive = false
        end

        Net::FTP.open(ip, username, password) do |ftp|
          if timeout
            ftp.open_timeout = timeout
            ftp.read_timeout = timeout
          end
          ftp.passive = true if passive_mode
          yield ftp
        end
      end

      def transfer!
        connection do |ftp|
          create_remote_path(ftp)

          package.filenames.each do |filename|
            src = File.join(Config.tmp_path, filename)
            dest = File.join(remote_path, filename)
            Logger.info "Storing '#{ip}:#{dest}'..."
            ftp.put(src, dest)
          end
        end
      end

      # Called by the Cycler.
      # Any error raised will be logged as a warning.
      def remove!(package)
        Logger.info "Removing backup package dated #{package.time}..."

        remote_path = remote_path_for(package)
        connection do |ftp|
          package.filenames.each do |filename|
            ftp.delete(File.join(remote_path, filename))
          end

          ftp.rmdir(remote_path)
        end
      end

      ##
      # Creates (if they don't exist yet) all the directories on the remote
      # server in order to upload the backup file. Net::FTP does not support
      # paths to directories that don't yet exist when creating new
      # directories. Instead, we split the parts up in to an array (for each
      # '/') and loop through that to create the directories one by one.
      # Net::FTP raises an exception when the directory it's trying to create
      # already exists, so we have rescue it
      def create_remote_path(ftp)
        path_parts = []
        remote_path.split("/").each do |path_part|
          path_parts << path_part
          begin
            ftp.mkdir(path_parts.join("/"))
          rescue Net::FTPPermError; end
        end
      end
    end
  end
end
