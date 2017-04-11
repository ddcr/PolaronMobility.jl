# FeynmanKadanoffOsakaHellwarth.jl
# Codes by Jarvist Moore Frost, 2017
# Calculate Polaron Mobility - by a Osaka/Hellwarth variational solution to the Feynman model
# If you run this, it should construct the model, solve for varying temperature, then produce plots as .pngs in the local directory.
# These codes were developed with Julia 0.5.0, and requires the Optim and Plots packages.

# Physical constants
const hbar = const ħ = 1.05457162825e-34;          # kg m2 / s 
const eV = const q = const ElectronVolt = 1.602176487e-19;                         # kg m2 / s2 
const me=MassElectron = 9.10938188e-31;                          # kg
const Boltzmann = const kB =  1.3806504e-23;                  # kg m2 / K s2 
const ε_0 = 8.854E-12 #Units: C2N−1m−2, permittivity of free space

# via Feynman 1955
#   http://dx.doi.org/10.1103/PhysRev.97.660
function feynmanalpha(ε_Inf,ε_S,freq,m_eff)
    ω=freq*2*pi #frequency to angular velocity
    # Note to self - you've introduced the 4*pi factor into the dielectric constant; 
    # This gives numeric agreement with literature values, but I'm uncertain of the justification.
    # Such a factor also seems to be necessary for calculation of Exciton binding energies (see below).
    # Maybe scientists in the 50s assumed that the Epsilon subsumed the 4*pi factor?
    α=0.5* (1/ε_Inf - 1/ε_S)/(4*pi*ε_0) * (q^2/(hbar*ω)) * (2*me*m_eff*ω/hbar)^0.5
    return (α)
end

" Copy and pasted out of a Jupyter notebook; this calculates 'alpha' parameters
for various materials, as a comparison to the literature used when figuring out
the oft-quoted units. "
function checkalpha()
	println(" Alpha-parameter, Cross check vs. literature values.\n")
	println("\t NaCl Frohlich paper α=",feynmanalpha(2.3, 5.6, (4.9E13/(2*pi)), 1.0)) 
    println(" should be ~about 5 (Feynman1955)")
	println("\t CdTe  α=",feynmanalpha(7.1,   10.4,  5.08E12, 0.095)) 
    println(" Stone 0.39 / Devreese 0.29 ")
	println("\t GaAs  α=",feynmanalpha(10.89, 12.9,  8.46E12, 0.063)) 
    println(" Devreese 0.068 ")

    println()
    println("Guess at PCBM: 4.0, 6.0 ; α=",feynmanalpha(4.0,6.0, 1E12, 50))
    println("MAPI:")
    println("MAPI  4.5, 24.1, 9THz ; α=",feynmanalpha(4.5,   24.1,  9.0E12,    0.12))
    println("MAPI  4.5, 24.1, 2.25THz - 75 cm^-1 ; α=",feynmanalpha(4.5,   24.1,  2.25E12,    0.12))
    println("MAPI  6.0, 25.7, 9THz ; α=",feynmanalpha(6.0,   25.7,  9.0E12,    0.12))
    println("MAPI  6.0, 36.0, 9THz ; α=",feynmanalpha(6.0,   36,  9.0E12,    0.12))
    println("MAPI  6.0, 36.0, 1THz ; α=",feynmanalpha(6.0,   36,  1.0E12,    0.12))
end
#checkalpha()

#####
# Set up the simulation parameters

# Internally we have 'mb' for the 'band mass' in SI units, of the effecitve-mass of the electron
effectivemass=0.12 # the bare-electron band effective-mass. 
# --> 0.12 for electrons and 0.15 for holes, in MAPI. See 2014 PRB.
mb=effectivemass*MassElectron 

# MAPI  4.5, 24.1, 2.25THz - 75 cm^-1 ; α=
# PCBM: 4.0, 5.0, 2.25Thz, effective-mass=1.0
ε_Inf=4.5
ε_S=24.1

freq=2.25E12 # 2.25 THz
ω = (2*pi)*freq # angular-frequency

α=feynmanalpha(ε_Inf, ε_S,  freq,    effectivemass)
#α=2.395939683378253 # Hard coded; from MAPI params, 4.5, 24.1, 2.25THz, 0.12me

@printf("Polaron mobility input parameters: ε_Inf=%f ε_S=%f freq=%g α=%f \n",ε_Inf, ε_S, freq, α )
@printf("Derived params in SI: ω =%g mb=%g \n",ω ,mb)

#####
# Set up equations for the polaron free energy, which we will variationally improve upon

# Hellwarth 1999 PRB - Part IV; T-dep of the Feynman variation parameter
# Originally a Friday afternoon of hacking to try and implement the T-dep electron-phonon coupling from the above PRB
# Which was unusually successful! And more or less reproduced Table III

# one-dimensional numerical integration in Julia using adaptive Gauss-Kronrod quadrature
using QuadGK

# Equation numbers follow above Hellwarth 1999 PRB
# 62b
A(v,w,β)=3/β*( log(v/w) - 1/2*log(2*π*β) - log(sinh(v*β/2)/sinh(w*β/2)))
# 62d
Y(x,v,β)=1/(1-exp(-v*β))*(1+exp(-v*β)-exp(-v*x)-exp(v*(x-β)))
# 62c integrand
f(x,v,w,β)=(exp(β-x)+exp(x))/(w^2*x*(1-x/β)+Y(x,v,β)*(v^2-w^2)/v)^(1/2)
# 62c
B(v,w,β,α) = α*v/(sqrt(π)*(exp(β)-1)) * quadgk(x->f(x,v,w,β),0,β/2)[1]
#62e
C(v,w,β)=3/4*(v^2-w^2)/v * (coth(v*β/2)-2/(v*β))

F(v,w,β,α)=-(A(v,w,β)+B(v,w,β,α)+C(v,w,β)) #(62a)

# Can now evaluate, e.g.
# F(v,w,β,α)=F(7.2,6.5,1.0,1.0)
# BUT - this is just the objective function! (The temperature-dependent free-energy.) Not the optimised parameters.
# Also there's a scary numeric integration (quadgk) buried within...

#####
# OK, let's use the powerful Julia Optim package to optimise the variational parameters
using Optim

# Initial v,w to use
initial=[7.1,6.5]
# Main use of these bounds is stopping v or w going negative, at which you get a NaN error as you are evaluating log(-ve Real)
lower=[0.1,0.1]
upper=[100.0,100.0]

# Empty arrays for storing data 
Ts=[]
Kμs=[]
Hμs=[]
FHIPμs=[]
ks=[]
Ms=[]
As=[]
Bs=[]
Cs=[]
Fs=[]

# We define βred as the subsuming the energy of the phonon; i.e. kbT c.f. ħω
for T in 10:10:400
    β=1/(kB*T)
    βred=ħ*ω*β
    @printf("T: %f β: %.2g βred: %.2g\t",T,β,βred)
    myf(x) = F(x[1],x[2],βred,α) # Wraps the function so just the two variational params are exposed
    res=optimize(DifferentiableFunction(myf), initial, lower, upper, Fminbox(); optimizer = BFGS, optimizer_o=Optim.Options(autodiff=true))
    minimum=Optim.minimizer(res)
    #show(Optim.converged(res)) # All came out as 'true'
    
    v=minimum[1]
    w=minimum[2]
        
    @printf(" v= %.2f w= %.2f\t",v,w)
        
    # From 1962 Feynman, definition of v and w in terms of the coupled Mass and spring-constant
    # See Page 1007, just after equation (18)
    # Units of M appear to be 'electron masses'
    # Unsure of units for k, spring coupling constant
    k=(v^2-w^2)
    M=(v^2-w^2)/w^2
    @printf(" M=%f k=%f\t",M,k)
    
    append!(ks,k)
    append!(Ms,M)
   
    # F(v,w,β,α)=-(A(v,w,β)+B(v,w,β,α)+C(v,w,β)) #(62a) - Hellwarth 1999
    @printf("\n Polaron Free Energy: A= %f B= %f C= %f F= %f",A(v,w,βred),B(v,w,βred,α),C(v,w,βred),F(v,w,βred,α))
    append!(As,A(v,w,βred))
    append!(Bs,B(v,w,βred,α))
    append!(Cs,C(v,w,βred))
    append!(Fs,F(v,w,βred,α))
    

    # FHIP 
    #    - low-T mobility, final result of Feynman1962
    # [1.60] in Devreese2016 page 36; 6th Edition of Frohlich polaron notes (ArXiv)
    # I believe here β is in SI (expanded) units
    μ=(w/v)^3 * (3*q)/(4*mb*ħ*ω^2*α*β) * exp(ħ*ω*β) * exp((v^2-w^2)/(w^2*v))
    @printf("\n\tμ(FHIP)= %f m^2/Vs \t= %.2f cm^2/Vs",μ,μ*100^2)
    append!(Ts,T)
    append!(FHIPμs,μ*100^2)
    

    # Kadanoff
    #     - low-T mobility, constructed around Boltzmann equation. 
    #     - Adds factor of 3/(2*beta) c.f. FHIP, correcting phonon emission behaviour
    # [1.61] in Devreese2016 - Kadanoff's Boltzmann eqn derived mob
    μ=(w/v)^3 * (q)/(2*mb*ω*α) * exp(ħ*ω*β) * exp((v^2-w^2)/(w^2*v))
    @printf("\n\tμ(Kadanoff)= %f m^2/Vs \t= %.2f cm^2/Vs",μ,μ*100^2)    

    append!(Kμs,μ*100^2)

    ######
    # OK, now deep-diving into Kadanoff1963 itself to extract Boltzmann equation components
    # Particularly right-hand-side of page 1367
    #
    # From 1963 Kadanoff, (9), define eqm. number of phonons (just from T and phonon omega)
    Nbar=(exp(βred) - 1)^-1
    @printf("\n\t Eqm. Phonon. pop. Nbar: %f",Nbar)

    #myv=sqrt(k*(1+M)/M) # cross-check maths between different papers
    #@printf("\nv: %f myv: %f\n",v,myv)

    # (Between 23 and 24 in Kadanoff 1963, for small momenta skip intergration
    Gamma0=2*α * Nbar * (M+1)^(1/2) * exp(-M/v)
    Gamma0*=ω  /(ω *hbar) # Kadanoff 1963 uses hbar=omega=mb=1 units
        # Factor of omega to get it as a rate relative to phonon frequency
        # Factor of omega*hbar to get it as a rate per energy window
    μ=q/( mb*(M+1) * Gamma0 ) #(25) Kadanoff 1963, with SI effective mass
    @printf("\n\tμ(Kadanoff [Eqn. 25]) = %f m^2/Vs \t = %.2f cm^2/Vs",μ,μ*100^2)
    @printf("\n\tGamma0 = %g Tau=1/Gamma0 = %g",
        Gamma0, 1/Gamma0) 

    # Hellwarth1999 Eqn (2) and (1) - These are going back to the general (pre low-T limit) formulas in Feynman1962.
    # to evaluate these, you need to do the explicit contour integration to get the polaron self-energy
    R=(v^2-w^2)/(w^2*v) # inline, page 300 just after Eqn (2)
    #b=R*βred/sinh(b*βred*v/2) # This self-references b! What on Earth?
    # OK! I now understand that there is a typo in Hellwarth1999 and
    # Biaggio1997. They've introduced a spurious b on the R.H.S. compared to
    # the original, Feynman1962...
    b=R*βred/sinh(βred*v/2) # Feynman1962 version; page 1010, Eqn (47b)
    a=sqrt( (βred/2)^2 + R*βred*coth(βred*v/2))
    k(u,a,b,v) = (u^2+a^2-b*cos(v*u))^(-3/2)*cos(u) # integrand in (2)
    K=quadgk(u->k(u,a,b,v),0,Inf)[1] # numerical quadrature integration of (2)
    
    #Right-hand-side of Eqn 1 in Hellwarth 1999 // Eqn (4) in Baggio1997
    RHS= α/(3*sqrt(π)) * βred^(5/2) / sinh(βred/2) * (v^3/w^3) * K
    μ=RHS^-1 * (q)/(ω*mb)
    @printf("\n\tμ(Hellwarth1999)= %f m^2/Vs \t= %.2f cm^2/Vs",μ,μ*100^2)    
    append!(Hμs,μ*100^2)
    
    #Hellwarth1999/Biaggio1997, b=0 version... 'Setting b=0 makes less than 0.1% error'
    R=(v^2-w^2)/(w^2*v) # inline, page 300 just after Eqn (2)
    b=0 
    a=sqrt( (βred/2)^2 + R*βred*coth(βred*v/2))
    k(u,a,b,v) = (u^2+a^2-b*cos(v*u))^(-3/2)*cos(u) # integrand in (2)
    K=quadgk(u->k(u,a,b,v),0,Inf)[1] # numerical quadrature integration of (2)

    #Right-hand-side of Eqn 1 in Hellwarth 1999 // Eqn (4) in Baggio1997
    RHS= α/(3*sqrt(π)) * βred^(5/2) / sinh(βred/2) * (v^3/w^3) * K
    μ=RHS^-1 * (q)/(ω*mb)
    @printf("\n\tμ(Hellwarth1999,b=0)= %f m^2/Vs \t= %.2f cm^2/Vs",μ,μ*100^2)
    @printf("\n\tError due to b=0; %f",(100^2*μ-Hμs[length(Hμs)])/(100^2*μ))
    #append!(Hμs,μ*100^2)
    
    
    @printf("\n\n")
    
    # Recycle previous variation results (v,w) as next guess
    initial=[v,w] # Caution! Might cause weird sticking in local minima
end

println("OK - everything calculated and stored. Now plotting figures..")

using Plots
default(size=(800,600))

#####
## Mass vs. Temperature plot
plot(Ts,Ms,label="Phonon effective-mass",marker=2,xlab="Temperature (K)",ylab="Phonon effective-mass (units bare-electron effective-masses)",ylim=(0,1.2))

savefig("mass.png")
savefig("mass.eps")

#####
## Spring Constants vs. Temperature plot
plot(Ts,ks,label="Polaron spring-constant",marker=2, xlab="Temperature (K)",ylab="Spring-const (some internal unit)",)

savefig("spring.png")
savefig("spring.eps")

#####
## Variation Energy vs. Temperature plots
plot(Ts,As,label="A",marker=2, xlab="Temperature (K)",ylab="Free-Energy")
plot!(Ts,Bs,label="B",marker=2)
plot!(Ts,Cs,label="C",marker=2)
plot!(Ts,Fs,label="F",marker=2)

savefig("variational.png")
savefig("variational.eps")

#####
## Calculated mobility comparison plot
plot(Ts,Kμs,label="Kadanoff",marker=2,xlab="Temperature (K)",ylab="Mobility (cm^2/Vs)",ylims=(0,1000))
plot!(Ts,FHIPμs,label="FHIP",marker=2)
plot!(Ts,Hμs,label="Hellwarth1999",marker=2)

savefig("mobility-calculated.png")
savefig("mobility-calculated.eps")

#####
## Expt. data to compare against
# Milot/Herz 2015 Time-Resolved-Microwave-Conductivity mobilities
# Data from table in SI of: DOI: 10.1002/adfm.201502340
# Absolute values possibly dodge due to unknown yield of charge carriers; but hopefully trend A.OK!
Milot= [
8 184
40 321
80 143
120 62
140 40
160 52
180 44
205 41
230 39
265 26
295 35
310 24
320 24
330 19
340 16
355 15 
]

# IV estimated mobilities (?!) from large single crystals, assumed ambient T
# Nature Communications 6, Article number: 7586 (2015)
# doi:10.1038/ncomms8586
Saidaminov = 
[ 300 67.2 ]

#Semonin2016,
#  doi = {10.1021/acs.jpclett.6b01308},
Semonin = 
[ 300 115 ] # +- 15 cm^2/Vs, holes+electrons

#####
## Calculated mobilities vs. expt
plot(Milot[:,1],Milot[:,2],label="Milot T-dep TRMC Polycrystal",
xlab="Temperature (K)",ylab="Mobility (cm^2/Vs)",marker=2, ylims=(0,400) )
plot!(Saidaminov[:,1],Saidaminov[:,2],label="Saidaminov JV Single Crystal", marker=6)
plot!(Semonin[:,1],Semonin[:,2],label="Semonin Single Crystal TRMC", marker=6)

plot!(Ts,Kμs,label="Kadanoff Polaron mobility",marker=2)
plot!(Ts,Hμs,label="Hellwarth1999 Polaron mobility",marker=2)

savefig("mobility-calculated-experimental.png")
savefig("mobility-calculated-experimental.eps")


println("That's me!")