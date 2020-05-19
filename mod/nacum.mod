TITLE Sodium ion accumulation
: Sodium ion accumulation inside and outside

NEURON {
	SUFFIX na
	USEION na READ ina, nai, nao WRITE nai, nao
	RANGE nai0, nao0
}

UNITS {
	(molar) = (1/liter)
	(mV) = (millivolt)
	(um) = (micron)
	(mM) = (millimolar)
	(mA) = (milliamp)
	FARADAY = 96520 (coul)
	R = 8.3134	(joule/degC)
}

PARAMETER {
	nabath = 116	(mM)
	ina		(mA/cm2)
	nai0 = 10 (mM)
	nao0 = 140 (mM)
}

ASSIGNED { diam (um) }

STATE {
	nai (mM)
	nao (mM)
}


INITIAL {
	nai = nai0
	nao = nao0
}

BREAKPOINT {
	SOLVE state METHOD cnexp
}

DERIVATIVE state {
	nai' = -ina * 4/(diam*FARADAY) * (1e4)
	nao' = 0
}
