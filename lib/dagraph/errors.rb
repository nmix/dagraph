
class CyclicError < ArgumentError; end
class SelfCyclicError < CyclicError; end
