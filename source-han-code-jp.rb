require 'yaml'

module YAMLDiff
  def diff_txt
    data_to_patch = DATAPatch.new :p1
    data_to_patch.path = Pathname __FILE__
    YAML.load data_to_patch.contents
  end
end

class Powerline < Formula
  extend YAMLDiff
  homepage 'https://github.com/powerline/fontpatcher'
  url 'https://github.com/powerline/fontpatcher/archive/18a788b8ec1822095813b73b0582a096320ff714.zip'
  sha1 'eacbca3a3e3b7acd03743e80a51de97c9c0bbc80'
  version '20150113'
  def initialize(name = 'powerline', path = Pathname(__FILE__), spec = 'stable')
    super
  end
  patch diff_txt[:powerline]
end

class Webdevicons < Formula
  extend YAMLDiff
  homepage 'https://github.com/ryanoasis/nerd-filetype-glyphs-fonts-patcher'
  version '0.2.0'
  url "https://github.com/ryanoasis/nerd-filetype-glyphs-fonts-patcher/archive/v#{version}.zip"
  sha1 'e17a7eba8a8da14ad51217efb8e7782d17b625ab'
  def initialize(name = 'nerd-tiletype-glyphs', path = Pathname(__FILE__), spec = 'stable')
    super
  end
  patch diff_txt[:webdevicons]
end

class SourceHanCodeJp < Formula
  homepage 'https://github.com/adobe-fonts/source-han-code-jp'
  version '1.002R'
  url "https://github.com/adobe-fonts/source-han-code-jp/archive/#{version}.002R.zip"
  sha1 'f225fbcf64e91ef1b77a5584b141d4f90e4e6874'

  option 'powerline', 'Patch for Powerline'
  option 'vim-powerline', 'Patch for Powerline from vim-powerline'
  option 'webdevicons', 'Patch for vim-webdevicons'
  option 'patch-in-place', "Patch Powerline glyphs directly into Ricty fonts without creating new 'for Powerline' fonts"

  depends_on 'fontforge'

  def install
    if build.include? 'powerline'
      powerline = Powerline.new
      powerline.brew { buildpath.install Dir['*'] }
      powerline.patch
      powerline_script << buildpath + 'scripts/powerline-fontpatcher'
      rename_from = "(#{self.class.name})-?"
      rename_to = "\\1 "
    end

    if build.include?('vim-powerline') && !(build.include?('powerline') && build.include?('patch-in-place'))
      resource('vimpowerline').stage { buildpath.install 'fontpatcher' }
      powerline_script << buildpath + 'fontpatcher/fontpatcher'
      rename_from = "\.ttf"
      rename_to = '-Powerline.ttf'
    end

    if build.include?('webdevicons')
      webdevicons = Webdevicons.new
      webdevicons.brew { buildpath.install Dir['*'] }
      webdevicons.patch
      webdevicons_script = buildpath + 'font-patcher'
    end

    share_fonts = share + 'fonts'
    otf_files = Dir["OTF/#{self.class.name}/*.otf"]

    if build.include?('powerline') || build.include?('vim-powerline')
      powerline_script.each do |script|
        ttf_files.each do |ttf|
          system "fontforge -lang=py -script #{script} #{powerline_args.join(' ')} #{ttf}"
          mv ttf.gsub(/#{rename_from}/, rename_to), ttf if build.include? 'patch-in-place'
        end
      end
    end

    if build.include?('webdevicons')
      ttf_files.each do |ttf|
        system "fontforge -lang=py -script #{webdevicons_script} #{ttf}"
      end
    end

    share_fonts.install Dir['Ricty*.ttf']
  end

  def caveats;
    generated = "#{share}/fonts/#{self.class.name}-*.otf"
    <<-EOS.undent
      ***************************************************
      Generated files:
        #{Dir[generated].join("\n      ")}
      ***************************************************
      To install Ricty:
        $ cp -f #{generated} ~/Library/Fonts/
        $ fc-cache -vf
      ***************************************************
    EOS
  end
end

__END__
:powerline: |
  diff --git a/scripts/powerline-fontpatcher b/scripts/powerline-fontpatcher
  index ed2bc65..094c974
  --- a/scripts/powerline-fontpatcher
  +++ b/scripts/powerline-fontpatcher
  @@ -73,0 +74,7 @@ class FontPatcher(object):
  +				# Ignore the above calculation and
  +				# manually set the best values for Ricty
  +				target_bb[0]=0
  +				target_bb[1]=-525
  +				target_bb[2]=1025
  +				target_bb[3]=1650
  +

:webdevicons: |
  diff --git a/font-patcher b/font-patcher
  index 74a2191..4e82b2a 100755
  --- a/font-patcher
  +++ b/font-patcher
  @@ -32,14 +32,6 @@ if args.single:

   sourceFont = fontforge.open(args.font)

  -# rename font
  -fontname, style = re.match("^([^-]*)(?:(-.*))?$", sourceFont.fontname).groups()
  -sourceFont.familyname = sourceFont.familyname + additionalFontNameSuffix
  -sourceFont.fullname = sourceFont.fullname + additionalFontNameSuffix
  -sourceFont.fontname = fontname + additionalFontNameSuffix.replace(" ", "")
  -sourceFont.appendSFNTName('English (US)', 'Preferred Family', sourceFont.familyname)
  -sourceFont.appendSFNTName('English (US)', 'Compatible Full', sourceFont.fullname)
  -
   # glyph font

   sourceFont_em_original = sourceFont.em
  @@ -80,34 +72,14 @@ symbols2.em = sourceFont.em
   # Initial font dimensions
   font_dim = {
   	'xmin'  :    0,
  -	'ymin'  :    -sourceFont.descent,
  -	'xmax'  :    0,
  -	'ymax'  :    sourceFont.ascent,
  +	'ymin'  :    -525,
  +	'xmax'  :    1025,
  +	'ymax'  :    1650,

  -	'width' :    0,
  -	'height':    0,
  +	'width' :    1025,
  +	'height':    2175,
   }

  -# Find the biggest char width and height
  -#
  -# 0x00-0x17f is the Latin Extended-A range
  -# 0x2500-0x2600 is the box drawing range
  -for glyph in range(0x00, 0x17f) + range(0x2500, 0x2600):
  -	try:
  -		(xmin, ymin, xmax, ymax) = sourceFont[glyph].boundingBox()
  -	except TypeError:
  -		continue
  -
  -	if font_dim['width'] == 0:
  -		font_dim['width'] = sourceFont[glyph].width
  -
  -	if ymin < font_dim['ymin']: font_dim['ymin'] = ymin
  -	if ymax > font_dim['ymax']: font_dim['ymax'] = ymax
  -	if xmax > font_dim['xmax']: font_dim['xmax'] = xmax
  -
  -# Calculate font height
  -font_dim['height'] = abs(font_dim['ymin']) + font_dim['ymax']
  -
   # Update the font encoding to ensure that the Unicode glyphs are available
   sourceFont.encoding = 'ISO10646'

  @@ -239,7 +211,7 @@ extension = os.path.splitext(sourceFont.path)[1]
   # @todo later add option to generate the sfd?
   #sourceFont.save(sourceFont.fullname + ".sfd")

  -sourceFont.generate(sourceFont.fullname + extension)
  +sourceFont.generate(sourceFont.path)

   print "Generated"
   print sourceFont.fullname
