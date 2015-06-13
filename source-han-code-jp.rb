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
  url "https://github.com/adobe-fonts/source-han-code-jp/archive/#{version}.zip"
  sha1 'f225fbcf64e91ef1b77a5584b141d4f90e4e6874'

  option 'powerline', 'Patch for Powerline'
  option 'webdevicons', 'Patch for vim-webdevicons'

  depends_on 'fontforge'

  def install
    font_name = self.class.name.split('::')[-1]

    if build.include? 'powerline'
      powerline = Powerline.new
      powerline.brew { buildpath.install Dir['*'] }
      powerline.patch
      powerline_script = buildpath + 'scripts/powerline-fontpatcher'
    end

    if build.include? 'webdevicons'
      webdevicons = Webdevicons.new
      webdevicons.brew { buildpath.install Dir['*'] }
      webdevicons.patch
      webdevicons_script = buildpath + 'font-patcher'
    end

    share_fonts = share + 'fonts'
    otf_files = Dir["OTF/#{font_name}/*.otf"]
    powerline_args = ['--no-rename']

    if build.include? 'powerline'
      otf_files.each do |otf|
        system "fontforge -lang=py -script #{powerline_script} #{powerline_args.join(' ')} #{otf}"
        mv 'None.otf', otf
      end
    end

    if build.include?('webdevicons')
      otf_files.each do |ttf|
        system "fontforge -lang=py -script #{webdevicons_script} #{ttf}"
      end
    end

    share_fonts.install Dir['Ricty*.ttf']
  end

  def caveats;
    generated = "#{share}/fonts/#{self.class.name.split('::')[-1]}-*.otf"
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
  --- a/scripts/powerline-fontpatcher	2015-06-13 18:40:18.000000000 +0900
  +++ b/scripts/powerline-fontpatcher	2015-06-13 18:41:50.000000000 +0900
  @@ -71,6 +71,13 @@
   				if bbox[3] > target_bb[3]:
   					target_bb[3] = bbox[3]

  +				# Ignore the above calculation and
  +				# manually set the best values for Ricty
  +				target_bb[0]=0
  +				target_bb[1]=-525
  +				target_bb[2]=1025
  +				target_bb[3]=1650
  +
   			# Find source and target size difference for scaling
   			x_ratio = (target_bb[2] - target_bb[0]) / (source_bb[2] - source_bb[0])
   			y_ratio = (target_bb[3] - target_bb[1]) / (source_bb[3] - source_bb[1])
  @@ -105,10 +112,7 @@
   			target_font.em = target_font_em_original

   			# Generate patched font
  -			extension = os.path.splitext(target_font.path)[1]
  -			if extension.lower() not in ['.ttf', '.otf']:
  -				# Default to OpenType if input is not TrueType/OpenType
  -				extension = '.otf'
  +			extension = '.otf'
   			target_font.generate('{0}{1}'.format(target_font.fullname, extension))

   fp = FontPatcher(args.source_font, args.target_fonts, args.rename_font)

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
