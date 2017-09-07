require 'rails_helper'
require 'spec_helper'

RSpec.describe User, type: :model do
  let(:included_modules) { described_class.included_modules }

  it 'has UserRoles functionality' do
    expect(included_modules).to include(::DamsUserRoles)
    expect(subject).to respond_to(:campus?)
  end

  it 'has Hydra Role Management behaviors' do
    expect(included_modules).to include(Hydra::RoleManagement::UserRoles)
    expect(subject).to respond_to(:admin?)
  end

  describe "#campus" do
    context "when access from campus" do
      subject do
        ip = '127.0.0.1'
        Rails.configuration.campus_ip_blocks << ip
        described_class.anonymous(ip)
      end

      it "is true" do
        expect(subject.campus?).to be_truthy
      end
    end
  end

  describe ".find_or_create_for_developer" do
    it "create a User for a new patron" do
      token = { 'info' => { 'email' => nil } }
      allow(token).to receive_messages(uid: 'test_user', provider: 'developer')
      user = User.find_or_create_for_developer(token)

      expect(user).to be_persisted
      expect(user.provider).to eq('developer')
      expect(user.uid).to eq('test_user')
    end

    it "reuse an existing User if the access token matches" do
      token = { 'info' => { 'email' => nil } }
      allow(token).to receive_messages(uid: 'test_user', provider: 'developer')
      User.find_or_create_for_developer(token)

      expect { User.find_or_create_for_developer(token) }.not_to change(User, :count)
    end
  end

  describe ".find_or_create_for_shibboleth" do
    before :all do
      @port = 1389

      @domain                 = "dc=example,dc=com"
      @toplevel_user_dn       = "cn=toplevel_user,cn=TOPLEVEL,#{@domain}"
      @toplevel_user_password = "toplevel_password"

      @regular_user_cn        = "regular_user"
      @regular_user_dn        = "cn=#{@regular_user_cn},ou=USERS,#{@domain}"
      @regular_user_password  = "regular_password"
      @regular_user_email     = "#{@regular_user_cn}@example.com"
      @addable_user_cn        = "addable_user"
      @addable_user_dn        = "cn=#{@addable_user_cn},ou=USERS,#{@domain}"
      @addable_user_password  = "addable_password"
      @addable_user_email     = "#{@addable_user_cn}@example.com"

      @server = FakeLDAP::Server.new(:port => @port)
      @server.run_tcpserver
      @server.add_user(@toplevel_user_dn, @toplevel_user_password)
      @server.add_user(@regular_user_dn, @regular_user_password, @regular_user_email)
    end

    after :all do
      @server.stop
    end
 
    before :each do
      @client = Net::LDAP.new     
      @client.port = @port
      @client.auth(@toplevel_user_dn, @toplevel_user_password)
      @client.bind_as(base: "#{@domain}", filter: "(cn=#{@toplevel_user_dn}*)", password: @toplevel_user_password)
    end
 
    it "create a User when a user is first authenticated" do
      token = { 'info' => { 'email' => nil } }
      allow(token).to receive_messages(uid: 'test_user', provider: 'shibboleth')
      user = User.find_or_create_for_shibboleth(token)

      expect(user).to be_persisted
      expect(user.provider).to eq('shibboleth')
      expect(user.uid).to eq('test_user')
    end
  end
end
