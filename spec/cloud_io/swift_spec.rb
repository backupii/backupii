require File.expand_path("../../spec_helper.rb", __FILE__)
require "backup/cloud_io/swift"

module Backup
  describe CloudIO::Swift do
    let(:connection) { double(:connection) }
    let(:directory) { double(:directory) }
    let(:files) { double(:files) }
    let(:fd) { double(:fd) }
    let(:response) { double(:response) }
    let(:cloud_io) do
      CloudIO::Swift.new(container: "my_bucket", batch_size: 5, max_retries: 0)
    end

    describe "#upload" do
      context "when file is larger than 5GB" do
        before do
          expect(File).to receive(:size).with('/src/file')
                            .and_return(5 * 1024**3)
        end

        it "raises an error" do
          expect do
            cloud_io.upload("/src/file", "idontcare")
          end.to raise_error CloudIO::FileSizeError
        end
      end

      context "when file is smaller than 5GB" do
        before do
          expect(File).to receive(:size).with("/src/file").and_return(512)
          expect(File).to receive(:open).with("/src/file").and_return(fd)
        end

        it "class #create on the directory" do
          expect(cloud_io).to receive(:directory).and_return(directory)
          expect(directory).to receive(:files).and_return(files)
          expect(files).to receive(:create).with(key: '/dst/file', body: fd)

          cloud_io.upload("/src/file", "/dst/file")
        end
      end
    end

    describe "#objects" do
      it "call #files on the container model" do
        expect(cloud_io).to receive(:directory).twice.and_return(directory)
        expect(directory).to receive(:files).twice.and_return(files)
        expect(files).to receive(:all).twice.with(prefix: '/prefix/')

        cloud_io.objects("/prefix")
        cloud_io.objects("/prefix/")
      end
    end

    describe "#delete" do
      let(:key_1) { ["file/path"] }
      let(:key_10) { (0...10).to_a.map { |id| "/path/to/file/#{id}" } }
      before do
        expect(cloud_io).to receive(:connection).and_return(connection)
      end

      it "calls connection#delete_multiple_objects" do
        expect(connection).to receive(:delete_multiple_objects)
                                .with('my_bucket', key_1)
                                .and_return(response)
        expect(response).to receive(:data).and_return(status: 200)

        expect { cloud_io.delete key_1 }.to_not raise_error
      end

      it "raises an error if status != 200" do
        expect(response).to receive(:data).
                              at_least(3).times
                              .and_return(
                                status: 503,
                                reason_phrase: "give me a reason",
                                body: "bodybody"
                              )
        expect(connection).to receive(:delete_multiple_objects)
                                .with('my_bucket', key_1)
                                .and_return(response)

        expect { cloud_io.delete key_1 }.to raise_error { |err|
          expect(err.message).to match(/Failed to delete/)
          expect(err.message).to match(/503/)
          expect(err.message).to match(/give me a reason/)
          expect(err.message).to match(/bodybody/)
        }
      end
    end
  end
end
