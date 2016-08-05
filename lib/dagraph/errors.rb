
class CyclicError < ArgumentError; end
class SelfCyclicError < CyclicError; end
class DuplicationError < ArgumentError; end;
