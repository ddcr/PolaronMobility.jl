# PolaronMobility.jl Documentation

## Introduction

These codes calculate the temperature-dependent polaron mobility for
a material.
We have parameters for various metal-halide Perovskite.

It is perhaps easiest to read this documentation alongside the pre-print:
[ArXiv:1704.05404](https://arxiv.org/abs/1704.05404) .

The scientific inputs are the dielectric constants, a characteristic phonon
frequency, and the bare-electron band effective-mass.

From this you can solve a temperature-dependent polaron model (variationally
optimising temperature-dependent free-energies for the coupled electron-phonon
system), and from this optimised parameters calculate derivative quantities
such as the polaron mobility, and polaron features (effective masses, energy
loss rates, oscillation etc.)

May your phonons drag in a manner truly sublime.

## Scientific discussion

These codes solve Osaka's variational method for solving the Feynman model.
For each temperature, the total free energy of the Feynman coupled
phonon-electron system is minimised by optimising coefficients which control
the spring-coupling coefficient and effective-mass for the phonon cloud.

The codes then calculate the polaron mobility, with both the original low-temperature
FHIP approximation [Feynman1962], Kadanoff's [Kadanoff1964] Boltzmann equation
motivated phonon-emission correction to the FHIP, and Hellwarth's
[Hellwarth1999] method of returning to an earlier (non low-temperature) result
in Feynman1962, then directly calculating the contour integral for the polaron
self-energy with numerical integration.

Underlying all this is the simplified Frohlich Hamiltonian [Frohlich1952] for
a single electron interacting with a phonon cloud of non-interacting (harmonic)
phonons.
The electron-phonon interaction is particularly simple, just considering
a dipole interaction.
This is folded into a dimensionless `alpha` parameter, practically constructed
from dielectric constants of a material, and a characteristic frequency of the
dielectric response.
(In a simple covalent semiconductor system, this is the frequency of the
linear-optical mode, the only infrared active one.)
The Feynman model is a beautiful solution of this most simple quantum field
problem where the quantum field variable of the phonon field is integrated out
by the path-integral approach to quantum mechanics, to leave an electron
interacting via a spring constant with an effective mass---a single particle
problem.

These Julia codes use Hellwarth's [Hellwarth1999] presentation of Osaka's variational
free-energies for the Feynman model.
We optimise the `v` and `w` parameters for these finite-temperature free energies.
These can be alternatively restated the mass 'M' and spring-constant 'k' of the
coupled phonon-electron Feynman model.

Here we apply these methods to the case of hybrid halide perovskites.
The method provides the temperature dependent polaron-mobility without any free parameters.
No arbitrary relaxation time is needed or used. The scattering processes are
treated directly, by including an effective electron-phonon coupling in the
specification of the Frohlich 'alpha' parameter, and then all other features
come from solving the model.
The original Feynman model is correct to all orders in alpha, and the Hellwarth
direct contour-integration of the general Feynman mobility statement is
suitable for high temperature.

It was necessary to return to these (rather old!) papers and resolve the
models, as hybrid halide perovskites are soft materials with low energy
phonons. Therefore the effective temperature in terms of a reduced
thermodynamic beta (Beta=hbar omega / (k_Boltzmann * Temperature) ) is much
smaller than previously considered.

A finaly note that in [Hellwarth1999], there is a mistake in the formula for 'b',
which is also present in their prior PRL [Biaggio1997].
It is correct in [Feynman1962], where there is no factor of b on the right-hand
side.
It doesn't matter too much, as setting it to zero makes ~0.1% difference in the
eventual mobility.
However, since we're integrating numerically anyway, we may as well calculate
it explicitly.


## Research outputs

Polaron mobilities, three different ways
![Polaron mobilities, three different ways](mobility-calculated.png)

Effective mass of phonon cloud
![Effective mass of phonon cloud](mass.png)

Spring constant for coupling to phonon cloud
![Spring constant for coupling to phonon cloud](spring.png)

Variational (temperature-dependent free-energy) parameters for the coupled system
![Variational (temperature-dependent free-energy) parameters for the coupled system](variational.png)

## Notes

26th June 2017: The code works (and appears to be faster) with the new stable
version of Julia (0.6). However, it still depends on the 0.7.x interface of
`Optim`. Therefore, if you want to use these codes with Julia 0.6 or beyond,
for now you have to pin your Optim package to this old(er) interface.

```
Pkg.pin("Optim",v"0.7.8")
```

## Bibliography

A bibliography in vague order of utility; I recommend reading the first ones first!

Feynman also describes his Polaron model in more detail in both 'Statistical
Mechanics' (Feynman1972) and 'Quantum Mechanics and Path Integrals'
(FeynmanHibbs1965). Note that the differing presentations of Feynman do not always agree in detail.

Schulman's 'Techniques and applications of path integration' has a 10-page
chapter on the Polaron problem. It tries to unify the Feynman prescriptions.

J.T. Devreese's "Fröhlich Polarons. Lecture course including detailed
theoretical derivations" (6th edition, 2016) notes on the ArXiv is a very good
place to start & to get an overview of the area.
https://arxiv.org/abs/1611.06122


```

% This introduces two prescriptions for reducing a multi-mode polar lattice to
% a single ~mean-field~ response.
% It contains a modern version of the Osaka finite temperature free-energies
% for use in a variational solution of the Feynman temperature problem.
% It also includes how to (numerically) do the contour integration to get the
% DC-response of the polaron developed in Feynman1962.
@article{Hellwarth1999,
  doi = {10.1103/physrevb.60.299},
  url = {https://doi.org/10.1103%2Fphysrevb.60.299},
  year  = {1999},
  month = {jul},
  publisher = {American Physical Society ({APS})},
  volume = {60},
  number = {1},
  pages = {299--307},
  author = {Robert W. Hellwarth and Ivan Biaggio},
  title = {Mobility of an electron in a multimode polar lattice},
  journal = {Physical Review B}
}

% Boltzmann / relaxation time approximation solution of mobility in the Feynman
% polaron problem.
% We extract a relaxation time (+ offer this method of mobility).
@article{Kadanoff1963,
  doi = {10.1103/physrev.130.1364},
  url = {https://doi.org/10.1103%2Fphysrev.130.1364},
  year  = {1963},
  month = {may},
  publisher = {American Physical Society ({APS})},
  volume = {130},
  number = {4},
  pages = {1364--1369},
  author = {Leo P. Kadanoff},
  title = {Boltzmann Equation for Polarons},
  journal = {Physical Review}
}

% A long and very useful article developing response theories for the polaron.
% Mainly known for the FHIP mobility, which is low-temperature only.
@article{Feynman1962,
  doi = {10.1103/physrev.127.1004},
  url = {https://doi.org/10.1103%2Fphysrev.127.1004},
  year  = {1962},
  month = {aug},
  publisher = {American Physical Society ({APS})},
  volume = {127},
  number = {4},
  pages = {1004--1017},
  author = {R. P. Feynman and R. W. Hellwarth and C. K. Iddings and P. M. Platzman},
  title = {Mobility of Slow Electrons in a Polar Crystal},
  journal = {Physical Review}
}

% The original development of Feynman's solution to the polaron problem.
% Zero temperature approximate variational solutions developed (in limits w->0,
% or w=v).
% Perturbative theories of phonon-drag effective-mass renormalisation given.
% (i.e. where the 'me=1+alpha/6' & etc. limits are from. )
@article{Feynman1955,
  doi = {10.1103/physrev.97.660},
  url = {https://doi.org/10.1103%2Fphysrev.97.660},
  year  = {1955},
  month = {feb},
  publisher = {American Physical Society ({APS})},
  volume = {97},
  number = {3},
  pages = {660--665},
  author = {R. P. Feynman},
  title = {Slow Electrons in a Polar Crystal},
  journal = {Physical Review}
}

% Schultz seemed to spend his PhD solving the Feynman polaron problem with
% a digital computer.
% Lots of characterisation of the polaron state, and the introduction of an
% effective polaron size, from considering the variance of the Gaussian
% wavefunction.
% Some work towards polaron mobility, but not as developed as in Feynman et al. 1962.
% Schultz provides units for some of the quantities - which is useful!
@article{Schultz1959,
  doi = {10.1103/physrev.116.526},
  url = {https://doi.org/10.1103%2Fphysrev.116.526},
  year  = {1959},
  month = {nov},
  publisher = {American Physical Society ({APS})},
  volume = {116},
  number = {3},
  pages = {526--543},
  author = {T. D. Schultz},
  title = {Slow Electrons in Polar Crystals: Self-Energy,  Mass,  and Mobility},
  journal = {Physical Review}
}

% Free-energies of the finite interacting Polaron system.
@article{Osaka1961,
  doi = {10.1143/ptp.25.517},
  url = {https://doi.org/10.1143%2Fptp.25.517},
  year  = {1961},
  month = {apr},
  publisher = {Oxford University Press ({OUP})},
  volume = {25},
  number = {4},
  pages = {517--536},
  author = {Yukio \=Osaka},
  title = {Theory of Polaron Mobility},
  journal = {Progress of Theoretical Physics}
}

% Original statement of the Polaron problem + Frohlich Hamiltonian.
@article{Frohlich1952,
  doi = {10.1098/rspa.1952.0212},
  url = {https://doi.org/10.1098%2Frspa.1952.0212},
  year  = {1952},
  month = {dec},
  publisher = {The Royal Society},
  volume = {215},
  number = {1122},
  pages = {291--298},
  author = {H. Frohlich},
  title = {Interaction of Electrons with Lattice Vibrations},
  journal = {Proceedings of the Royal Society A: Mathematical,  Physical and Engineering Sciences}
}

@article{Thornber1970,
  doi = {10.1103/physrevb.1.4099},
  url = {https://doi.org/10.1103%2Fphysrevb.1.4099},
  year  = {1970},
  month = {may},
  publisher = {American Physical Society ({APS})},
  volume = {1},
  number = {10},
  pages = {4099--4114},
  author = {K. K. Thornber and Richard P. Feynman},
  title = {Velocity Acquired by an Electron in a Finite Electric Field in a Polar Crystal},
  journal = {Physical Review B}
}

```

## Functions provided 

```@docs
feynmanalpha(ε_Inf,ε_S,freq,m_eff)
```

```@docs
HellwarthBScheme(LO)
```

```@docs
HellwarthAScheme(LO,T=295)
```

```@docs
savepolaron(fileprefix, p::Polaron)
```

```@docs
plotpolaron(fileprefix, p::Polaron; extension="png")
```

```@docs
ImX(nurange,v,w,βred,α,ω,mb)
```

```@docs
polaronmobility(fileprefix,Trange, ε_Inf, ε_S,  freq,    effectivemass; figures::Bool=true, verbose::Bool=false)
```
