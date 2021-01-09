
class User_File

	attr_accessor :total_size, :data_size, :file_type, :data_offset, :data

	def initialize(total_size, data_size, file_type, data_offset, data)
		@total_size 	= total_size
		@data_size   	= data_size
		@file_type   	= file_type
		@data_offset 	= data_offset
		@data 			= data
	end

	def output_info
		puts "File type is: #{@file_type}"
		puts "Total file size: #{@total_size} bytes."
		if @file_type == ".bmp"
			puts "The data offset starts at byte: #{@data_offset}"
		end
		puts "The total size of the data itself is: #{@data_size} bytes."
		puts "At an encode rate of 8 to 1, payload size can be no more than: #{(@data_size - 32) / 8} bytes."
	end

	#So, I hate this function.
	#Encode the binary representation of the secret into the LSB's of the file's data
	def stego_encode(msg_file)
		arr = string_to_bin(msg_file).reverse #reverse for pop
		len = arr.length

		#Starting at the beginning of the pixel data, check if the LSB of the pixel
		#matches the next bit in the binary array. No action needed if a match.
		data[data_offset..data_offset + len - 1].each_with_index{
			|e, i|

			x = arr.pop

			if (e % 2).to_i == x.to_i
				#The LSB matches the message bit, we can safely skip here
			else
				#The LSB doesn't match, so we need to inc(or decr) to encode
				if e == 255
					data[data_offset+i] -= 1
				else
					data[data_offset+i] += 1
				end
			end
		}
	end
end

#Read a file - Open, read in, and close a file
def read_file(file)
	begin
		input_file = File.open(file)
	rescue
		raise "Can't find file with that name"
	end

	file_type = File.extname(input_file)

	if file_type == ".bmp"
		data_array	= input_file.read.unpack("C*")
		total_size	= input_file.size
		data_offset	= get_data_offset(data_array.slice(10..13))#Not pretty, but these 4 bytes are the data offset.
		data_size	= input_file.size - data_offset
	else
		raise "Couldn't recognize file type. Must be a .bmp file."
	end

	input_file.close#Or sherri will kill me telepathically

	working_file = User_File.new(	total_size,
									data_size,
									file_type,
									data_offset,
									data_array)
end

#Write a file - Generates new file in current directory.
def write_file(data)
	output_file = data.pack("C*")

	begin
		File.open("stego_out.bmp", "w") {|file| file.write(output_file)}
	rescue
		raise "File's cooked"
	end
end

#Get the data offset from either the cover image or stego image.
def get_data_offset(data_array)
	#This will be returned as an int indicating the byte the data starts at
	data_array.reverse.map{|e| "%08b" % e}.join.to_i(2)
end

#String in, binary representation out
def string_to_bin(string)
	size = pay_size_enc(string.length)
	data = string.unpack("B*")[0].split("")

	ans = size.concat(data)
end

#Write payload size as a 32 bit int signature
def pay_size_enc(total_size)
	#The 32 here is for the 4 added bytes denoting the total size of the payload
	size_signature = (8 * total_size + 32).to_s(2) #8 for bits per byte

	#Pad 0's here I think(bad commenting)
	size_signature = (("0" * (32 - size_signature.size)) + size_signature).split('')
end

#Extract payload from stego file
#Messy as soon as I start adding (more) magic constants
def stego_extract(file)
	stego_file = read_file(file)

	offset = stego_file.data_offset
	data = stego_file.data

	#the 31/32 is the offset for the size I encode.
	msg_size = data[offset..offset+31].map{|e| e % 2}.join.to_i(2) - 1
	
	binary = data[offset+32..offset+msg_size].map{|e| e % 2}
	
	secret = ""
	binary.each_slice(8){
		|a|
		secret << a.join.to_i(2).chr
	}
	
	secret
end