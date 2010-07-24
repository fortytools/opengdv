# A contract, i.e. everything between the Vorsatz and Nachsatz
class GDV::Model::Contract < GDV::Model::Base
    attr_reader :partner, :general, :signatures, :clauses, :rebates
    attr_reader :specific

    def self.parse(reader)
        reader.parse(self) do
            object :partner, GDV::Model::Partner
            # Allgemeiner Teil
            one    :general, :satz => GENERAL_CONTRACT
            star   :signatures, :satz => SIGNATURES
            star   :clauses, :satz => CLAUSES
            star   :rebates, :satz => REBATES
            # Spartenspezifischer Teil
            one    :specific, :satz => SPECIFIC_CONTRACT
            skip_until :satz => [ADDRESS_TEIL, NACHSATZ]
        end
    end
end
