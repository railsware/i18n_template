require './test/test_helper'

describe I18nTemplate do
  include I18nTestCaseHelper

  describe ".escape" do
    subject { I18nTemplate.escape(@phrase) }

    it "should escape double quote" do
      @phrase = %q("Hello" World)
      @result = "[quot]Hello[quot] World"

      assert_equal(@result, subject)
    end

    it "should escape curly brackets" do
      @phrase = %q(Hello #{user})
      @result = %q(Hello #[lcb]user[rcb])

      assert_equal(@result, subject)
    end

    it "should escape square brackets" do
      @phrase = %q(Hello #[user])
      @result = %q(Hello #[lsb]user[rsb])

      assert_equal(@result, subject)
    end

    it "should NOT change source" do
      @phrase = %q("Hello" World).freeze
      subject
      assert_equal(%q("Hello" World), @phrase)
    end
  end

  describe ".unescape" do
    subject { I18nTemplate.unescape(@phrase) }
    it "should unescape [qout]" do
      @phrase = "[quot]Hello[quot] World"
      @result = %q("Hello" World)

      assert_equal(@result, subject)
    end

    it "should unescape [lcb] and [rcb]" do
      @phrase = %q(Hello #[lcb]user[rcb])
      @result = %q(Hello #{user})

      assert_equal(@result, subject)
    end

    it "should unescape [lsb] and [rsb]" do
      @phrase = %q(Hello #[lsb]user[rsb])
      @result = %q(Hello #[user])

      assert_equal(@result, subject)
    end

    it "should NOT change source" do
      @phrase = "[quot]Hello[quot] World"
      subject
      assert_equal("[quot]Hello[quot] World", @phrase)
    end
  end

  describe ".escape!" do
    subject { I18nTemplate.escape!(@phrase) }

    it "escape source" do
      @phrase = %q("Hello" [World] {today})
      @result = "[quot]Hello[quot] [lsb]World[rsb] [lcb]today[rcb]"
      subject
      assert_equal(@result, @phrase)
    end
  end

  describe ".unescape!" do
    subject { I18nTemplate.unescape!(@phrase) }

    it "unescape source" do
      @phrase = "[quot]Hello[quot] [lsb]World[rsb] [lcb]today[rcb] [1]"
      @result = %q("Hello" [World] {today} [1])

      subject
      assert_equal(@result, @phrase)
    end
  end

  describe "#t" do

    describe "when only phrase given" do
      subject { I18nTemplate.t(@phrase) } 

      it "should return the same value with tilda if no translation found" do
        @phrase = "Hello World"
        @result = "~Hello World"

        assert_equal(@result, subject)
      end

      it "should return unescaped phrase" do
        @phrase = "[quot]Hello[quot] World"
        @result = %q(~"Hello" World)

        assert_equal(@result, subject)
      end

      it "should remove interpolate brackets" do
        @phrase = "Hello [1]World![/1][2/] Username:[3]{1}[/3]"
        @result = "~Hello World! Username:"

        assert_equal(@result, subject)
      end
    end


    describe "when phrase and interpolate values given" do
      subject { I18nTemplate.t(@phrase, @values) } 

      it "should replace interpolate brackets with values" do
        @phrase = "Hello [1]World![/1][2/] Username:[3]{1}[/3]"
        @values = {
          '[1]'  => "<i>",
          '[/1]' => "</i>",
          '[2/]' => "<br />",
          '[3]'  => "<span class=\"username\">",
          '[/3]' => "</span>",
          '{1}'  => "Bob"
        }
        @result = %q(~Hello <i>World!</i><br /> Username:<span class="username">Bob</span>)

        assert_equal(@result, subject)
      end
    end

    describe "when translation given" do
      subject { I18nTemplate.t(@phrase, @values) } 

      it "should replace interpolate brackets with values" do
        @phrase = "Hello [1]World![/1][2/] Username:[3]{1}[/3]"
        @translation = "Benutzername: [3]{1}[/3][2/] Hallo [1]die Welt![/1]"
        @values = {
          '[1]'  => "<i>",
          '[/1]' => "</i>",
          '[2/]' => "<br />",
          '[3]'  => "<span class=\"username\">",
          '[/3]' => "</span>",
          '{1}'  => "Bob"
        }
        @result = %q(Benutzername: <span class="username">Bob</span><br /> Hallo <i>die Welt!</i>)

        add_translation(@phrase, @translation)
        assert_equal(@result, subject)
      end

      it "should remove brackets without interpolation" do
        @phrase = "Hello [1]World![/1][2/] Username:[3]{1}[/3]"
        @translation = "Benutzername: {1}. Hallo [10]die Welt![/10]"
        @values = {
          '[1]'  => "<i>",
          '[/1]' => "</i>",
          '[2/]' => "<br />",
          '[3]'  => "<span class=\"username\">",
          '[/3]' => "</span>",
          '{1}'  => "Bob"
        }
        @result = %q(Benutzername: Bob. Hallo die Welt!)

        add_translation(@phrase, @translation)
        assert_equal(@result, subject)
      end
    end

  end
end
