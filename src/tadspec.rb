
class ErrorAsercion < RuntimeError

end

module TadSpecEnabledObject
  def deberia(matcher)
    unless matcher.call(self)
      raise ErrorAsercion.new(
                "#{self} no cumplió assertion #{matcher}"
            )
    end
  end
end

module Matcher
  def ser(algo)
    if algo.is_a? Proc
      algo
    else
      ser_igual(algo)
    end
  end

  def no(un_matcher)
    proc { |a_comparar| !un_matcher.call(a_comparar) }
  end

  def ser_igual(a_algo)
    proc { |a_comparar| a_comparar == a_algo }
  end

  alias_method :igual, :ser_igual

  def ser_menor_a(a_algo)
    proc { |a_comparar| a_comparar < a_algo }
  end

  alias_method :menor_a, :ser_menor_a

  def method_missing(name, *args, &block)
    if name.to_s.start_with? "tener_"
      atributo = ("@" + name.to_s.gsub("tener_", "")).to_sym

      matcher = ser(args[0])

      proc { |a_matchear|
        matcher.call(a_matchear.instance_variable_get(atributo))
      }
    else
      super
    end
  end
end

module Mocking
  def self.mocks_definidos
    @mocks_definidos ||= []
  end

  def mockear(metodo, &bloque)
    metodo_original = instance_method metodo
    define_method metodo, &bloque
    Mocking.mocks_definidos.push(
        {
            mod: self,
            nombre: metodo,
            original: metodo_original
        }
    )
  end

  def self.revertir_mocks
    self.mocks_definidos.each do |definicion|
      definicion[:mod].define_method(
          definicion[:nombre],
          definicion[:original])
    end
    self.mocks_definidos.clear
  end
end

module TadSpec
  def self.init
    Object.include TadSpecEnabledObject
    Module.include Mocking
  end

  def self.testear(una_suite) #una_suite es una clase
    self.init
    metodos_a_testear =
        una_suite.instance_methods.select do |method|
          method.to_s.start_with? "testear_que_"
        end

    metodos_a_testear.map do |un_metodo|
      ejecutar_test(un_metodo, una_suite)
    end
  end

  def self.ejecutar_test(un_metodo_de_test, una_suite)
    un_contexto = una_suite.new
    un_contexto.singleton_class.include Matcher
    resultado = begin
      un_contexto.send un_metodo_de_test

      ResultadoTest.new(
          un_metodo_de_test,
          una_suite,
          :paso)

    rescue ErrorAsercion => e
      ResultadoTest.new(
          un_metodo_de_test,
          una_suite,
          :fallo,
          e
      )
    rescue => e
      ResultadoTest.new(
          un_metodo_de_test,
          una_suite,
          :error,
          e
      )
    end

    Mocking.revertir_mocks

    resultado
  end
end

class ResultadoTest
  attr_accessor :nombre, :suite, :estado, :exception

  def initialize(nombre, suite, estado, exception = nil)
    self.nombre = nombre
    self.suite = suite
    self.estado = estado
    self.exception = exception
  end
end
