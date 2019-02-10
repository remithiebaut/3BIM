library(phaseR)
library(deSolve)


rm(list=ls()) #reinitialiser variables


Eq3 = function(t,x,parameters) #modèle complexe
{
  with(as.list(c(parameters,x)),{
    dS = - beta*S*I  + alpha*(S+I+R) -lambda*S - theta*(S+I+R)*S/k
    dI =   beta*S*I - gamma*I - mu*I -lambda*I - theta*(S+I+R)*I/k
    dR =   mu*I - lambda*R - theta*(S+I+R)*R/k
    dD =   gamma*I + lambda*(R+I+S) + theta*(S+I+R)^2/k
    list(c(dS,dI,dR,dD))
  })
}



simulation_logistique = function(ini,inisansmaladie,parameters,maxtime,pasdetemps)
{
  #simulation sans infectés initiaux
  
  time=seq(0,maxtime,pasdetemps)
  solm=lsoda(func=Eq3,y=inisansmaladie,times=time,parms = parameters) #resoud
  morts_sans_maladie=solm[length(solm[,5]),5] #5eme colonne est celle des morts
  
  
  
  #simulation avec des infectés initiaux
  
  sol=lsoda(func=Eq3,y=ini,times=time,parms = parameters) #resoud
  
  
  #On cherche a regardersi l'épidémie s'éteint : le nombre d'infecté <1
  epidemie="endémique"
  fin_epidemie=NA
  for (j in 1:maxtime)
  {
    if (sol[j,3]<1) #moins d1 infecté => maladie éteinte
    {
      morts_pendant_maladie=sol[j,5]
      fin_epidemie=j #indice du temps à laquelle l'épidémie s'éteint
      epidemie="eteinte"
      break
    }
  }
  

  
  if (epidemie !="endémique")
  {
    
    
    #On relance une simulation pour continuer l'évolution après l'épidémie
    S=as.numeric(sol[fin_epidemie,2])
    I=0                               #round(as.numeric(sol[fin_epidemie,2]))
    R=as.numeric(sol[fin_epidemie,4])
    D=as.numeric(sol[fin_epidemie,5])
    continuer=c(S=S,I=I,R=R,D=D)
    time2=seq(0,maxtime-time[fin_epidemie],pasdetemps) # temps moins important
    
    sol2=lsoda(func=Eq3,y=continuer,times=time2,parms = parameters) #resoud
    
    morts_avec_maladie=sol2[length(sol2[,5]),5]
    
    #On combine les résultats pendant et après l'épidémie
    smaladie=c(sol[1:fin_epidemie-1,2],sol2[,2]) #on tronque pour ne pas compter 2 fois le jour final de l'épidémie
    imaladie=c(sol[1:fin_epidemie-1,3],sol2[,3])
    rmaladie=c(sol[1:fin_epidemie-1,4],sol2[,4])
    dmaladie=c(sol[1:fin_epidemie-1,5],sol2[,5])
  }
  else
  {
    #On récupère les données épidémiologiques à la fin de l'épidémie
    smaladie=sol[,2]
    imaladie=sol[,3]
    rmaladie=sol[,4]
    dmaladie=sol[,5]
    morts_avec_maladie=sol[length(sol[,5]),5]
    morts_pendant_maladie=morts_avec_maladie
  }
  
  #affichage des courbes
  par(mfrow=c(2,1)) # 2 fig
  
  plot(x=time,y=smaladie,xlab="Temps",ylab="Population",type="l",ylim=c(0,900),col="green",main = "Graphique avec maladie")
  points(x = time,imaladie,col="red",type="l")
  points(x = time,rmaladie,col="blue",type="l")
  points(x = time,dmaladie,col="black",type="l")
  
  
  plot(x=time,y=solm[,2],xlab="Temps",ylab="Population",type="l",ylim=c(0,900),col="green",main = "Graphique sans maladie")
  points(x = time,solm[,3],col="red",type="l")
  points(x = time,solm[,4],col="blue",type="l")
  points(x = time,solm[,5],col="black",type="l")
  
  #autre résultat intéresant : la somme des "années" de vies de tous les individus
  années_de_vie_sans_maladie=( sum(solm[,2])+sum(solm[,3])+sum(solm[,4]) ) 
  années_de_vie_avec_maladie=( sum(smaladie)+sum(imaladie)+sum(rmaladie) ) 
  
  #renvoi des résultats
  list(c(epidemie=epidemie,fin_epidemie=fin_epidemie,morts_sans_maladie=morts_sans_maladie,
         morts_pendant_maladie=morts_pendant_maladie,morts_avec_maladie=morts_avec_maladie,
         années_de_vie_sans_maladie=années_de_vie_sans_maladie, années_de_vie_avec_maladie=années_de_vie_avec_maladie ))
}


#Données

beta=0.00225 #infectiosité
gamma=0.04 #mortalité
mu=0.04 #recouvrement
N=300 #pop initiale
I=1 #infecté initiale
lambda=0.001 #morts naturelles
alpha=0.002 #naissances naturelles
theta=alpha-lambda #pression démographique
k=800 #capacité limite
parameters=c(beta=beta,gamma=gamma,N=N,mu=mu,lambda=lambda,alpha=alpha,theta=theta,k=k)
ini=c(S=N-I,I=I,R=0,D=0)
inisansmaladie=c(S=N,I=0,R=0,D=0)
maxtime=5000
pasdetemps=1




#1 On montre que le modèle est correcte : 

#en initialisant sansinfecté dans les deux cas on obtient bien les mème résultats
#De plus on observe bien els résultats attends pour une population suivant le modèle logistique

testblanc=simulation_logistique(ini=inisansmaladie ,inisansmaladie=inisansmaladie,
                           parameters=parameters,maxtime=maxtime,pasdetemps=pasdetemps)
print(testblanc)



#2) On test pour différentes valeurs de K :

#D'après nos résultats on a systématiquement un nombre de morts 
#plus faible dans le cas d'une pandémie que quand il n'y en a pas

# Il faut noter que si l'épidémie est endémique, 
# la capacité limite effective de la population est réduite

#Comme attendu la somme des années de vie est en faveur de la situation sans maladie
#Dans ce cas la on a en effet une population qui est plus longtemps importante

parameters=c(beta=beta,gamma=gamma,N=N,mu=mu,lambda=lambda,alpha=alpha,theta=theta,k=N*2) #capacité limite > Pop départ
testksup=simulation_logistique(ini=ini,inisansmaladie=inisansmaladie,parameters=parameters,
                           maxtime=maxtime,pasdetemps=pasdetemps)
print(testksup)


parameters=c(beta=beta,gamma=gamma,N=N,mu=mu,lambda=lambda,alpha=alpha,theta=theta,k=N) #capacité limite = Pop départ
testkegal=simulation_logistique(ini=ini,inisansmaladie=inisansmaladie,parameters=parameters,
                           maxtime=maxtime,pasdetemps=pasdetemps)
print(testkegal)


parameters=c(beta=beta,gamma=gamma,N=N,mu=mu,lambda=lambda,alpha=alpha,theta=theta,k=N/2) #capacité limite < que  Pop départ
testkinf=simulation_logistique(ini=ini,inisansmaladie=inisansmaladie,parameters=parameters,
                           maxtime=maxtime,pasdetemps=pasdetemps)
print(testkinf)