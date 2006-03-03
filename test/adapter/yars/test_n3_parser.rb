require 'test/unit'
require 'yars_adapter'

class TestTriple < Test::Unit::TestCase

	def test_resource
		assert_match Yars::Resource, '<http://eyal>'
		assert_match Yars::Resource, '<test:eyal>'
		assert_no_match Yars::Resource, '_:123'
		assert_no_match Yars::Resource, '_:abcde'
		assert_no_match Yars::Resource, ''
		assert_no_match Yars::Resource, '<>'
		assert_no_match Yars::Resource, '_: 123'
	end
	
	def test_subj
		assert_match Yars::Subj, '<http://eyal>'
		assert_match Yars::Subj, '<test:eyal>'
		assert_match Yars::Subj, '_:123'
		assert_match Yars::Subj, '_:abcde'
		assert_no_match Yars::Subj, ''
		assert_no_match Yars::Subj, '<>'
		assert_no_match Yars::Subj, '_: 123'
	end

	def test_obj
		assert_match Yars::Obj, '<http://eyal>'
		assert_match Yars::Obj, '_:123'
		assert_match Yars::Obj, '"test"'
		assert_match Yars::Obj, '"test test test"'
		assert_no_match Yars::Obj, '<>'
		assert_no_match Yars::Obj, '<http://eyal'
	end

	def test_triple
		assert_match Yars::NTriple, '<http://eyal> <test:test> "hello" .'
		assert_match Yars::NTriple, '<http://eyal> <test:test> <hello> .'
		assert_no_match Yars::NTriple, 'abcdef <http://eyal> <test:test> <hello> .'
		assert_no_match Yars::NTriple, ' <http://eyal> ... <test:test> <hello> .'
		assert_no_match Yars::NTriple, ' <http://eyal> ... <test:test> ... <hello> .'
		assert_no_match Yars::NTriple, ' <http://eyal> <test:test> <hello> '
		assert_no_match Yars::NTriple, ' <http://eyal> ... <hello> .'
	end

	def extract_triple
		test1 = '<http://eyal> <test:test> "hello" .'
		test2 = '_:123 <test:test> _:111 .'
		test3 = '_:123 <test:test> <subj> .'

		Yars::NTriple.match test1
		assert_match $1, 'http://eyal'
		assert_equal $3, 'test:test'
		assert_equal $6, 'hello'

		Yars::NTriple.match test2
		assert_equal $2, '123'
		assert_equal $3, 'test:test'
		assert_equal $5, '111'

		Yars::NTriple.match test3
		assert_equal $2, '123'
		assert_equal $3, 'test:test'
		assert_equal $4, 'subj'
	end
end
