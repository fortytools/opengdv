require 'test_helper'

class TestModel < Test::Unit::TestCase
    def test_transmission
        transmission "muster_bestand.gdv"

        assert_equal 1, @transmission.packages.size
        assert_equal data_file("muster_bestand.gdv"), @package.filename
        assert_equal 1, @transmission.packages.size

        assert_equal("9999", @package.vunr)
        d = Date.civil(2004, 7, 22)
        assert_equal(d, @package.created_from)
        assert_equal(d, @package.created_until)

        assert_equal(14, @package.contracts.size)
        c = @package.contracts.first
        p = c.vn
        assert_equal("2", p.anrede_raw)
        assert_equal("Frau", p.anrede)
        assert_equal("", p.geburtsort)

        assert_equal("Frau", p.address.anredeschluessel)
        assert_equal("Martina", p.address.name3)
        g = c.general
        assert_not_nil g
        assert_equal("EUR", g[1].raw(21))
        assert_equal("B4LTTT", g[1][25])
    end

    def test_multiple_partner
        transmission "multiple_addresses.gdv"

        assert_equal 1, @package.contracts.size
        contract = @package.contracts[0]
        vn = contract.vn
        assert_equal "Kunde", vn.address.name1
        assert_equal "Versicherungsnehmer", vn.address.adress_kennzeichen
        assert_equal "01", vn.address[1].raw(:adress_kennzeichen)

        assert_equal 1, contract.partner.size
        partner = contract.partner[0]
        assert_equal "Vermittler", partner.address.name1
        assert_equal "Vermittler", partner.address.adress_kennzeichen
        assert_equal "14", partner.address[1].raw(:adress_kennzeichen)
    end

    def test_kfz
        transmission "muster_bestand.gdv"

        contracts = contracts_for(GDV::Model::Sparte::KFZ)
        assert_equal(4, contracts.size)

        c = contracts.first
        assert_not_nil c

        assert_equal("Gillensvier", c.vn.nachname)
        assert_equal("Herbert", c.vn.vorname)
        assert_equal("W45KKK", c.vn.kdnr_vu)

        assert_equal("59999999990", c.vsnr)
        assert_equal(Date.civil(2004, 7, 1), c.begin_on)
        assert_equal(Date.civil(2005,1,1), c.end_on)
        assert_equal(Date.civil(2005,1,1), c.renewal)

        kfz = c.sparte
        assert_equal("VW", kfz.make)
        assert_equal('1J (GOLF IV 1.9 TDI SYNCR', kfz.model)
        assert_equal(0, kfz.price)

        assert_not_nil kfz.haft
        assert_equal("R8", kfz.haft.regionalklasse)
        assert_equal("1/2", kfz.haft.sfs)
        assert_equal(866.87, kfz.haft.beitrag)

        assert_not_nil kfz.teil
        assert_equal("22", kfz.teil.typkl)
        assert_equal(173.58, kfz.teil.beitrag)

        assert_not_nil kfz.unfall
        assert_equal("1", kfz.unfall.deckung1_raw)
        assert_equal(30000.0, kfz.unfall.invaliditaet)
    end

    def test_multi_package
        # Generated by concatenating
        # multiple_addresses.gdv muster_bestand.gdv multiple_addresses.gdv
        transmission "multi_package.gdv"

        assert_equal 3, @transmission.packages.size
        assert_equal 16, @transmission.contracts_count
        assert_equal 15, @transmission.unique_contracts_count
    end

    def test_yaml_contract
        transmission "muster_bestand.gdv"

        contracts = contracts_for(GDV::Model::Sparte::KFZ)
        assert_equal(4, contracts.size)

        c = YAML::load(contracts.first.to_yaml)

        assert_equal("Gillensvier", c.vn.nachname)
        assert_equal("Herbert", c.vn.vorname)
        assert_equal("W45KKK", c.vn.kdnr_vu)

        assert_equal("59999999990", c.vsnr)
        assert_equal(Date.civil(2004, 7, 1), c.begin_on)
        assert_equal(Date.civil(2005,1,1), c.end_on)
        assert_equal(Date.civil(2005,1,1), c.renewal)

        kfz = c.sparte
        assert_equal("VW", kfz.make)
        assert_equal('1J (GOLF IV 1.9 TDI SYNCR', kfz.model)
        assert_equal(0, kfz.price)

        assert_not_nil kfz.haft
        assert_equal("R8", kfz.haft.regionalklasse)
        assert_equal("1/2", kfz.haft.sfs)
        assert_equal(866.87, kfz.haft.beitrag)

        assert_not_nil kfz.teil
        assert_equal("22", kfz.teil.typkl)
        assert_equal(173.58, kfz.teil.beitrag)

        assert_not_nil kfz.unfall
        assert_equal("1", kfz.unfall.deckung1_raw)
        assert_equal(30000.0, kfz.unfall.invaliditaet)
    end

    def test_cset
        transmission "muster_bestand.gdv"
        vn = @transmission.packages[0].contracts[0].vn
        assert_equal "Kitzelpf\xc3\xbctze", vn.nachname
    end

    def test_garbage
        assert_raises GDV::Format::MatchError do
            transmission "garbage.gdv"
        end
        assert_raises GDV::Format::MatchError do
            transmission "missing_nachsatz.gdv"
        end
    end

    def contracts_for(sp)
        @package.contracts.select { |c| c.sparte?(sp) }
    end

    def transmission(filename)
        @transmission = GDV::Model::Transmission.new(data_file(filename))
        @package = @transmission.packages.first
    end
end
