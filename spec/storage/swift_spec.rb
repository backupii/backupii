# encoding: utf-8

require File.expand_path("../../spec_helper.rb", __FILE__)

module Backup
  describe Storage::Swift do
    let(:model) { Model.new(:test_trigger, "test label") }

    let(:required_config) do
      proc do |sw|
        sw.auth_url             = "auth_url"
        sw.username             = "username"
        sw.password             = "password"
        sw.container            = "container"
      end
    end
    let(:storage) { Storage::Swift.new(model, &required_config) }
    let(:s) { sequence "" }

    it_behaves_like "a class that includes Config::Helpers" do
      let(:default_overrides) do
        { "chunk_size" => 15,
          "encryption" => :aes256,
          "storage_class" => :reduced_redundancy }
      end
      let(:new_overrides) do
        { "chunk_size" => 20,
          "encryption" => "aes256",
          "storage_class" => "standard" }
      end
    end

    it_behaves_like "a subclass of Storage::Base"
    it_behaves_like "a storage that cycles"

    describe "#initialize" do
      it "provides defaults values" do
        # Required
        expect(storage.auth_url).to eq "auth_url"
        expect(storage.username).to eq "username"
        expect(storage.password).to eq "password"
        expect(storage.container).to eq "container"

        # Defaults
        expect(storage.max_retries).to eq 10
        expect(storage.retry_waitsec).to eq 30
        expect(storage.path).to eq "backups"
        expect(storage.batch_size).to eq 1000
        expect(storage.fog_options).to be_empty

        expect(storage.tenant_name).to be_nil
        expect(storage.region).to be_nil
      end

      it "configures the storage" do
        storage = Storage::Swift.new(model, :test_id) do |sw|
          sw.keep               = 2
          sw.auth_url           = "url".freeze
          sw.username           = "user".freeze
          sw.password           = "pass".freeze
          sw.tenant_name        = "tenant"
          sw.container          = "cont"
          sw.region             = "fr"
          sw.max_retries        = 4
          sw.retry_waitsec      = 2
          sw.batch_size         = 23
          sw.fog_options        = { fog: "option" }
        end

        expect(storage.storage_id).to eq "test_id"
        expect(storage.keep).to eq 2
        expect(storage.username).to eq "user"
        expect(storage.password).to eq "pass"
        expect(storage.tenant_name).to eq "tenant"
        expect(storage.container).to eq "cont"
        expect(storage.region).to eq "fr"
        expect(storage.max_retries).to eq 4
        expect(storage.retry_waitsec).to eq 2
        expect(storage.batch_size).to eq 23
        expect(storage.fog_options[:fog]).to eq "option"
      end

      [:container, :auth_url, :username, :password].each do |key|
        it "requires #{key}" do
          pre_config = required_config
          expect do
            Storage::Swift.new(model) do |sw|
              pre_config.call(sw)
              sw.send("#{key}=", nil)
            end
          end.to raise_error { |err|
            expect(err.message).to match(/(is|are all) required/)
          }
        end
      end

      it "requires tenant_name when using v2 auth" do
        pre_config = required_config
        expect do
          Storage::Swift.new(model) do |sw|
            pre_config.call(sw)
            sw.auth_url = "http://nowhere/v2/tokens"
          end
        end.to raise_error { |err|
          expect(err.message).to match(/are all required/)
        }
      end
    end

    describe "#cloud_io" do
      it "creates instantiate a CloudIO::Swift object once" do
        expect(CloudIO::Swift).to receive(:new)
                                    .once
                                    .with(
                                      username: "username",
                                      password: "password",
                                      auth_url: "auth_url",
                                      container: "container",
                                      tenant_name: nil,
                                      region: nil,
                                      max_retries: 10,
                                      retry_waitsec: 30,
                                      batch_size: 1000,
                                      fog_options: {}
                                    ).and_return(:cloud_io)

        storage = Storage::Swift.new(model, &required_config)

        expect(storage.send(:cloud_io)).to eq :cloud_io
        expect(storage.send(:cloud_io)).to eq :cloud_io
      end
    end

    describe "#transfer!" do
      let(:cloud_io) { double(:cloud_io) }
      let(:timestamp) { Time.now.strftime("%Y.%m.%d.%H.%M.%S") }
      let(:remote_path) { File.join("my/path/test_trigger", timestamp) }

      before do
        Timecop.freeze
        storage.package.time = timestamp
        storage.package.stub(:filenames).and_return(
          ["test_trigger.tar-aa", "test_trigger.tar-ab"]
        )
        storage.stub(:cloud_io).and_return(cloud_io)
        storage.container = "my_bucket"
        storage.path = "my/path"
      end

      after { Timecop.return }

      it "transfers the package files" do
        src = File.join(Config.tmp_path, "test_trigger.tar-aa")
        dest = File.join(remote_path, "test_trigger.tar-aa")

        expect(Logger).to receive(:info)
                            .with("Storing 'my_bucket/#{dest}'...")
                            .ordered
        expect(cloud_io).to receive(:upload).with(src, dest).ordered

        src = File.join(Config.tmp_path, "test_trigger.tar-ab")
        dest = File.join(remote_path, "test_trigger.tar-ab")

        expect(Logger).to receive(:info)
                            .with("Storing 'my_bucket/#{dest}'...")
                            .ordered
        expect(cloud_io).to receive(:upload).with(src, dest).ordered

        storage.send(:transfer!)
      end
    end # describe '#transfer!'

    describe "#remove!" do
      let(:cloud_io) { double(:cloud_io) }
      let(:timestamp) { Time.now.strftime("%Y.%m.%d.%H.%M.%S") }
      let(:remote_path) { File.join("my/path/test_trigger", timestamp) }
      let(:package) do
        pkg = double(:package)
        pkg.stub(:trigger) { 'test_trigger' }
        pkg.stub(:time) { timestamp }
        pkg
      end

      before do
        Timecop.freeze
        storage.stub(:cloud_io).and_return(cloud_io)
        storage.container = "my_bucket"
        storage.path = "my/path"
      end

      after { Timecop.return }

      it "removes the given package from the remote" do
        expect(Logger)
          .to receive(:info)
                .with("Removing backup package dated #{timestamp}...")

        objects = ["some objects"]
        expect(cloud_io).to receive(:objects).with(remote_path)
                              .and_return(objects)
        expect(cloud_io).to receive(:delete).with(objects)

        storage.send(:remove!, package)
      end

      it "raises an error if remote package is missing" do
        objects = []
        expect(cloud_io).to receive(:objects).with(remote_path)
                              .and_return(objects)
        expect(cloud_io).not_to receive(:delete)

        expect do
          storage.send(:remove!, package)
        end.to raise_error(
                 Storage::Swift::Error,
                 "Storage::Swift::Error: Package at '#{remote_path}' not found"
               )
      end
    end # describe '#remove!'
  end
end
