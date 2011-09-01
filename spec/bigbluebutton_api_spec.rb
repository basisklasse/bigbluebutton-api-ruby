require 'spec_helper'

describe BigBlueButton::BigBlueButtonApi do
  let(:url) { "http://server.com" }
  let(:salt) { "1234567890abcdefghijkl" }
  let(:version) { "0.7" }
  let(:debug) { false }
  let(:api) { BigBlueButton::BigBlueButtonApi.new(url, salt, version, debug) }

  describe "#initialize" do
    context "standard initialization" do
      subject { BigBlueButton::BigBlueButtonApi.new(url, salt, version, debug) }
      it { subject.url.should be(url) }
      it { subject.salt.should be(salt) }
      it { subject.version.should be(version) }
      it { subject.debug.should be(debug) }
      it { subject.timeout.should be(2) }
      it { subject.supported_versions.should include("0.7") }
    end

    context "when the version is not informed, get it from the BBB server" do
      before { BigBlueButton::BigBlueButtonApi.any_instance.should_receive(:get_api_version).and_return("0.7") }
      subject { BigBlueButton::BigBlueButtonApi.new(url, salt, nil) }
      it { subject.version.should == "0.7" }
    end

    it "when the version is not supported raise an error" do
      expect {
        BigBlueButton::BigBlueButtonApi.new(url, salt, "0.not-supported", nil)
      }.to raise_error(BigBlueButton::BigBlueButtonException)
    end

    context "current supported versions" do
      subject { BigBlueButton::BigBlueButtonApi.new(url, salt) }
      it { subject.supported_versions.should == ["0.7"] }
    end
  end

  describe "#join_meeting_url" do
    let(:meeting_id) { "meeting-id" }
    let(:password) { "password" }
    let(:user_name) { "user-name" }
    let(:user_id) { "user-id" }
    let(:web_voice_conf) { "web-voice-conf" }
    let(:params) {
      { :meetingID => meeting_id, :password => password, :fullName => user_name,
        :userID => user_id, :webVoiceConf => web_voice_conf }
    }

    before { api.should_receive(:get_url).with(:join, params).and_return("test-url") }
    it { api.join_meeting_url(meeting_id, user_name, password, user_id, web_voice_conf).should == "test-url" }
  end

  pending "#create_meeting"

  describe "#end_meeting" do
    let(:meeting_name) { "name" }
    let(:meeting_id) { "meeting-id" }
    let(:moderator_password) { "moderator-password" }
    let(:attendee_password) { "attendee-password" }
    let(:welcome_message) { "welcome" }
    let(:dial_number) { "dial-number" }
    let(:logout_url) { "logout-url" }
    let(:max_participants) { "max-participants" }
    let(:voice_bridge) { "voice-bridge" }
    let(:params) {
      { :name => meeting_name, :meetingID => meeting_id,
        :moderatorPW => moderator_password, :attendeePW => attendee_password,
        :welcome => welcome_message, :dialNumber => dial_number,
        :logoutURL => logout_url, :maxParticpants => max_participants,
        :voiceBridge => voice_bridge }
    }
    let(:response) { { :meetingID => 123, :moderatorPW => 111, :attendeePW => 222, :hasBeenForciblyEnded => "false" } }

    before { api.should_receive(:send_api_request).with(:create, params).and_return(response) }
    subject { api.create_meeting(meeting_name, meeting_id, moderator_password,
                                 attendee_password, welcome_message, dial_number,
                                 logout_url, max_participants, voice_bridge) }
    it { subject.fetch(:meetingID).should == "123" }
    it { subject.fetch(:moderatorPW).should == "111" }
    it { subject.fetch(:attendeePW).should == "222" }
    it { subject.fetch(:hasBeenForciblyEnded).should == false }
  end

  describe "#is_meeting_running?" do
    let(:meeting_id) { "meeting-id" }
    let(:params) { { :meetingID => meeting_id } }

    context "when the meeting is running" do
      let(:response) { { :running => "true" } }
      before { api.should_receive(:send_api_request).with(:isMeetingRunning, params).and_return(response) }
      it { api.is_meeting_running?(meeting_id).should == true }
    end

    context "when the meeting is not running" do
      let(:response) { { :running => "false" } }
      before { api.should_receive(:send_api_request).with(:isMeetingRunning, params).and_return(response) }
      it { api.is_meeting_running?(meeting_id).should == false }
    end
  end

  describe "#join_meeting" do
    let(:meeting_id) { "meeting-id" }
    let(:password) { "password" }
    let(:user_name) { "user-name" }
    let(:user_id) { "user-id" }
    let(:web_voice_conf) { "web-voice-conf" }
    let(:params) {
      { :meetingID => meeting_id, :password => password, :fullName => user_name,
        :userID => user_id, :webVoiceConf => web_voice_conf }
    }

    before { api.should_receive(:send_api_request).with(:join, params).and_return("join-return") }
    it { api.join_meeting(meeting_id, user_name, password, user_id, web_voice_conf).should == "join-return" }
  end

  pending "#get_meeting_info"

  pending "#get_meetings"

  describe "#get_api_version" do
    context "returns the version returned by the server" do
      let(:hash) { { :returncode => true, :version => "0.7" } }
      before { api.should_receive(:send_api_request).with(:index).and_return(hash) }
      it { api.get_api_version.should == "0.7" }
    end

    context "returns an empty string when the server responds with an empty hash" do
      before { api.should_receive(:send_api_request).with(:index).and_return({}) }
      it { api.get_api_version.should == "" }
    end
  end

  describe "#test_connection" do
    context "returns the returncode returned by the server" do
      let(:hash) { { :returncode => "any-value" } }
      before { api.should_receive(:send_api_request).with(:index).and_return(hash) }
      it { api.test_connection.should == "any-value" }
    end
  end

  describe "#==" do
    let(:api2) { BigBlueButton::BigBlueButtonApi.new(url, salt, version, debug) }

    context "compares attributes" do
      it { api.should == api2 }
    end

    context "differs #debug" do
      before { api2.debug = !api.debug }
      it { api.should_not == api2 }
    end

    context "differs #salt" do
      before { api2.salt = api.salt + "x" }
      it { api.should_not == api2 }
    end

    context "differs #version" do
      before { api2.version = api.version + "x" }
      it { api.should_not == api2 }
    end

    context "differs #supported_versions" do
      before { api2.supported_versions << "x" }
      it { api.should_not == api2 }
    end
  end

  pending "#last_http_response"

  describe "#get_url" do

    context "when method = :index" do
      it { api.get_url(:index).should == api.url }
    end

    context "when method != :index" do
      context "validates the entire url" do
        context "with params" do
          let(:params) { { :param1 => "value1", :param2 => "value2" } }
          subject { api.get_url(:join, params) }
          it { subject.should match(/#{url}\/join\?param1=value1&param2=value2/) }
        end

        context "without params" do
          subject { api.get_url(:join) }
          it { subject.should match(/#{url}\/join\?[^&]/) }
        end
      end

      context "discards params with nil value" do
        let(:params) { { :param1 => "value1", :param2 => nil } }
        subject { api.get_url(:join, params) }
        it { subject.should_not match(/param2=/) }
      end

      context "escapes all params" do
        let(:params) { { :param1 => "value with spaces", :param2 => "@$" } }
        subject { api.get_url(:join, params) }
        it { subject.should match(/param1=value\+with\+spaces/) }
        it { subject.should match(/param2=%40%24/) }
      end

      context "includes the checksum" do
        let(:params) { { :param1 => "value1", :param2 => "value2" } }
        let(:checksum) { Digest::SHA1.hexdigest("joinparam1=value1&param2=value2#{salt}") }
        subject { api.get_url(:join, params) }
        it { subject.should match(/checksum=#{checksum}$/) }
      end
    end
  end

  # FIXME: this complex test means that the method is too complex - try to refactor it
  describe "#send_api_request" do
    let(:method) { :join }
    let(:params) { { :param1 => "value1" } }
    let(:target_url) { "http://test-server:8080?param1=value1&checksum=12345" }
    let(:make_request) { api.send_api_request(method, params) }
    before { api.should_receive(:get_url).with(method, params).and_return(target_url) }

    def setup_http_mock
      @http_mock = mock(Net::HTTP)
      Net::HTTP.should_receive(:new).with("test-server", 8080).and_return(@http_mock)
      @http_mock.should_receive(:"open_timeout=").with(api.timeout)
      @http_mock.should_receive(:"read_timeout=").with(api.timeout)
    end

    context "sets up the Net::HTTP object correctly" do
      before do
        setup_http_mock
        response_mock = mock()
        @http_mock.should_receive(:get).and_return(response_mock)
        response_mock.should_receive(:body).and_return("") # so the method exits right after the setup
      end
      it { make_request }
    end

    context "handles a TimeoutError" do
      before do
        setup_http_mock
        @http_mock.should_receive(:get) { raise TimeoutError }
      end
      it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
    end

    context "handles general Exceptions" do
      before do
        setup_http_mock
        @http_mock.should_receive(:get) { raise Exception }
      end
      it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
    end

    context "returns an empty hash if the response body is empty" do
      before do
        setup_http_mock
        response_mock = mock()
        @http_mock.should_receive(:get).and_return(response_mock)
        response_mock.should_receive(:body).and_return("")
      end
      it { make_request.should == { } }
    end

    context "hashfies and validates the response body" do
      before do
        setup_http_mock
        response_mock = mock()
        @http_mock.should_receive(:get).and_return(response_mock)
        response_mock.should_receive(:body).twice.and_return("response-body")
      end

      context "checking if it has a :response key" do
        before { Hash.should_receive(:from_xml).with("response-body").and_return({ }) }
        it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
      end

      context "checking if it the :response key has a :returncode key" do
        before { Hash.should_receive(:from_xml).with("response-body").and_return({ :response => { } }) }
        it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
      end
    end

    context "formats the response hash" do
      let(:response) { { :response => { :returncode => true } } }
      let(:formatted_response) { { :returncode => true } }
      before do
        setup_http_mock
        response_mock = mock()
        @http_mock.should_receive(:get).and_return(response_mock)
        response_mock.should_receive(:body).twice.and_return("response-body")
        Hash.should_receive(:from_xml).with("response-body").and_return(response)
        BigBlueButton::BigBlueButtonFormatter.should_receive(:default_formatting). # here's the validation
          with(response).and_return(formatted_response)
      end
      it { make_request }
    end

    context "raise an error if the formatted response has no :returncode" do
      let(:response) { { :response => { :returncode => true } } }
      let(:formatted_response) { { } }
      before do
        setup_http_mock
        response_mock = mock()
        @http_mock.should_receive(:get).and_return(response_mock)
        response_mock.should_receive(:body).twice.and_return("response-body")
        Hash.should_receive(:from_xml).with("response-body").and_return(response)
        BigBlueButton::BigBlueButtonFormatter.should_receive(:default_formatting).
          with(response).and_return(formatted_response)
      end
      it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
    end

  end

end