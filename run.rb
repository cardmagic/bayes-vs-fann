require 'bundler/setup'

require 'ruby-fann'
require 'classifier'
require './email_processor'

bayes = Classifier::Bayes.new 'spam', 'ham'


if File.file?("fann.train")
	train = RubyFann::TrainData.new(:filename => 'fann.train')
else
	good_inputs = Dir["training/ham/**/*"].map do |email|
		e = nil
		begin
			e = EmailProcessor.process_one_email(email)
			bayes.train_ham IO.read(email)
		rescue
			next
		end
		e.to_array
	end.compact

	good_outputs = good_inputs.map{|input| [1, -1]}

	bad_inputs = Dir["training/spam/**/*"].map do |email|
		e = nil
		begin
			e = EmailProcessor.process_one_email(email)
			bayes.train_spam IO.read(email)
		rescue
			next
		end
		e.to_array
	end.compact

	bad_outputs = bad_inputs.map{|input| [-1, 1]}

	inputs = good_inputs.concat(bad_inputs)
	outputs = good_outputs.concat(bad_outputs)

	training_data = RubyFann::TrainData.new(:inputs => inputs, :desired_outputs => outputs)
	training_data.save('fann.train')
end

if File.file?("fann.test")
	testing_data = RubyFann::TrainData.new(:filename => 'fann.test')
else
	good_inputs = Dir["testing/ham/**/*"].map do |email|
		begin
			e = EmailProcessor.process_one_email(email)
		rescue
			next
		end
		e.to_array
	end.compact

	good_outputs = good_inputs.map{|input| [1, -1]}

	bad_inputs = Dir["testing/spam/**/*"].map do |ham_email|
		e = EmailProcessor.process_one_email(ham_email) rescue next
		e.to_array
	end.compact

	bad_outputs = bad_outputs.map{|input| [1, -1]}

	inputs = good_inputs.concat(bad_inputs)
	outputs = good_outputs.concat(bad_outputs)

	testing_data = RubyFann::TrainData.new(:inputs => inputs, :desired_outputs => outputs)
	testing_data.save('fann.test')
end


fann = RubyFann::Standard.new(:num_inputs => 82, :hidden_neurons => [40, 40], :num_outputs => 2)
fann.train_on_data(training_data, 1000, 10, 0.1)
fann.test_data(testing_data)    

bayes.classify "I hate bad words and you"
