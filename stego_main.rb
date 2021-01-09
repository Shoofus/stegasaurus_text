load 'stego_header.rb'

#Could also include a small feature to watermark an image.
#Basically a small message(contained within say, 64-128 bits) repeated
#throughout the whole image(as many times as it will fit).

#Tests needed

#Currently sitting at working prototype. I can put a message in and get one out,
#needs lots of edge case testing as well as error handling. Plus, it's not
#very robust. Just .bmp's is sorta boring eh? There are likely a few libraries
#to make this easier. Quite the step up from the old c++ code I wrote.

#Create our data by reading the file in
new_file = read_file("mirri3.bmp")

#Little info check
new_file.output_info

#Our 'secret' message. String is easy to test and implement; this can be a whole other file though
message = "Hello, this is a test."

#Our data field will now have encoded the secret into it's LSB's
new_file.stego_encode(message)

#Write the file out of course.(New file in current directory)
write_file(new_file.data)

#Test of the secret extraction. Returns a string, the 'secret' message
puts stego_extract("stego_out.bmp")