# frozen_string_literal: true

require "spec_helper"

module Backup
  describe Notifier::Twitter do
    let(:model) { Model.new(:test_trigger, "test label") }
    let(:notifier) { Notifier::Twitter.new(model) }

    it_behaves_like "a class that includes Config::Helpers"
    it_behaves_like "a subclass of Notifier::Base"

    describe "#initialize" do
      it "provides default values" do
        expect(notifier.consumer_key).to be_nil
        expect(notifier.consumer_secret).to be_nil
        expect(notifier.oauth_token).to be_nil
        expect(notifier.oauth_token_secret).to be_nil

        expect(notifier.on_success).to be(true)
        expect(notifier.on_warning).to be(true)
        expect(notifier.on_failure).to be(true)
        expect(notifier.max_retries).to be(10)
        expect(notifier.retry_waitsec).to be(30)
      end

      it "configures the notifier" do
        notifier = Notifier::Twitter.new(model) do |twitter|
          twitter.consumer_key       = "my_consumer_key"
          twitter.consumer_secret    = "my_consumer_secret"
          twitter.oauth_token        = "my_oauth_token"
          twitter.oauth_token_secret = "my_oauth_token_secret"

          twitter.on_success    = false
          twitter.on_warning    = false
          twitter.on_failure    = false
          twitter.max_retries   = 5
          twitter.retry_waitsec = 10
        end

        expect(notifier.consumer_key).to eq "my_consumer_key"
        expect(notifier.consumer_secret).to eq "my_consumer_secret"
        expect(notifier.oauth_token).to eq "my_oauth_token"
        expect(notifier.oauth_token_secret).to eq "my_oauth_token_secret"

        expect(notifier.on_success).to be(false)
        expect(notifier.on_warning).to be(false)
        expect(notifier.on_failure).to be(false)
        expect(notifier.max_retries).to be(5)
        expect(notifier.retry_waitsec).to be(10)
      end
    end # describe '#initialize'

    describe "#notify!" do
      let(:message) { "[Backup::%s] test label (test_trigger)" }

      context "when status is :success" do
        it "sends a success message" do
          expect(notifier).to receive(:send_message).with(message % "Success")
          notifier.send(:notify!, :success)
        end
      end

      context "when status is :warning" do
        it "sends a warning message" do
          expect(notifier).to receive(:send_message).with(message % "Warning")
          notifier.send(:notify!, :warning)
        end
      end

      context "when status is :failure" do
        it "sends a failure message" do
          expect(notifier).to receive(:send_message).with(message % "Failure")
          notifier.send(:notify!, :failure)
        end
      end
    end # describe '#notify!'

    describe "#send_message" do
      let(:notifier) do
        Notifier::Twitter.new(model) do |twitter|
          twitter.consumer_key       = "my_consumer_key"
          twitter.consumer_secret    = "my_consumer_secret"
          twitter.oauth_token        = "my_oauth_token"
          twitter.oauth_token_secret = "my_oauth_token_secret"
        end
      end

      it "sends a message" do
        client = double
        config = double

        expect(::Twitter::REST::Client).to receive(:new).and_yield(config).and_return(client)
        expect(config).to receive(:consumer_key=).with("my_consumer_key")
        expect(config).to receive(:consumer_secret=).with("my_consumer_secret")
        expect(config).to receive(:access_token=).with("my_oauth_token")
        expect(config).to receive(:access_token_secret=).with("my_oauth_token_secret")

        expect(client).to receive(:update).with("a message")

        notifier.send(:send_message, "a message")
      end
    end # describe '#send_message'
  end
end
