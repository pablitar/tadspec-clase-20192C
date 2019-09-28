require 'rspec'
require_relative '../src/tadspec'


class Persona
  attr_accessor :nombre, :edad

  def initialize(nombre, edad = 22)
    self.nombre = nombre
    self.edad = edad
  end
end

describe 'assertions' do

  before :each do
    TadSpec.init
    self.singleton_class.include Matcher
  end

  it 'los strings objetos entienden deberia y pasan la assertion ser_igual' do
    mati = Persona.new("mati")

    mati.nombre.deberia(
        self.ser_igual("mati")) # equivalente a expect(mati.nombre).to eq("mati")

  end

  it 'deberia ejecuta la assertion y tira excepción si falla' do
    mati = Persona.new("mati")

    expect {
      mati.nombre.deberia ser_igual "pablo"
    }.to raise_error(ErrorAsercion)
  end

  it 'deberia poder usar la sintaxis nueva' do
    mati = Persona.new("mati")

    mati.nombre.deberia ser "mati"
    mati.nombre.deberia ser igual "mati"
    mati.nombre.length.deberia ser menor_a 5
  end

  it 'deberia poder usar la sintaxis nueva y fallar assertions' do
    mati = Persona.new("mati")

    [proc { mati.nombre.deberia ser "pablo" },
    proc { mati.nombre.deberia ser igual "pablo" },
    proc { mati.nombre.length.deberia ser menor_a 3 }].each do |proc|
      expect(&proc).to raise_error(ErrorAsercion)
    end
  end

  it 'deberia funcionar con tener' do
    mati = Persona.new("mati")

    mati.deberia tener_nombre "mati"
    mati.deberia tener_edad menor_a 30
  end

  it 'deberia correr la assertion con tener' do
    mati = Persona.new("mati")

    [proc {mati.deberia tener_nombre "pablo"},
    proc {mati.deberia tener_edad menor_a 10}].each do |proc|
      expect(&proc).to raise_error ErrorAsercion
    end
  end
end

describe 'suites' do

  class MiSuite
    def testear_que_1_es_menor_que_2
      1.deberia ser menor_a 2
    end

    def testear_que_2_es_menor_que_1
      2.deberia ser menor_a 1
    end

    def testear_que_3_sobre_0_explota
      (3 / 0).deberia ser "infinito"
    end

    def esto_no_es_un_test
      #nada
    end
  end

  describe "ejecutar solo un test" do
    before :each do
      TadSpec.init
    end

    it 'deberia ejecutar un test de una suite en particular que pasa' do
      resultado = TadSpec.ejecutar_test(
          :testear_que_1_es_menor_que_2, MiSuite)

      expect(resultado.estado).to be(:paso)
    end

    it 'deberia ejecutar un test de una suite en particular que no pasa' do
      resultado = TadSpec.ejecutar_test(
          :testear_que_2_es_menor_que_1, MiSuite)

      expect(resultado.estado).to be(:fallo)
      expect(resultado.exception).to be_a(ErrorAsercion)
    end

    it 'deberia ejecutar un test de una suite en particular que explota' do
      resultado = TadSpec.ejecutar_test(
          :testear_que_3_sobre_0_explota, MiSuite)

      expect(resultado.estado).to be(:error)
      expect(resultado.exception).to be_a(ZeroDivisionError)
    end
  end

  it 'deberia ejecutar todos los tests de una suite y obtener el resultado' do
    resultado = TadSpec.testear(MiSuite)

    expect(resultado.length).to be(3)

    resultado_que_paso = resultado.find {|un_r| un_r.nombre == :testear_que_1_es_menor_que_2}

    expect(resultado_que_paso.estado).to be(:paso)
  end
end