# Marcelo Araya-Salas 1-oct-2020
#
# La regresi�n escalonada es un procedimiento que podemos utilizar para construir un modelo de regresión a partir de un conjunto de variables predictoras candidatas ingresando y eliminando predictores de manera escalonada en el modelo hasta que no haya una raz�n "estad�sticamente v�lida" (seg�n sus ap�logos) para ingresar o quitar m�s.
#
# El objetivo de la regresi�n escalonada (nuevamente, seg�n sus defensores) es crear un modelo de regresi�n que incluya todas las variables predictoras que est�n relacionadas de manera estad�ticamente significativa con la variable de respuesta.
#
# La funci�n "replicar_reg_scal" en este c�digo replica la regresi�n escalonada (stepwise regression) usando simulaciones. La funci�n simula un juego de datos con m�ltiples variables predictoras con un n�mero de variables definidas por el usuario (nvars). Una de estas variables es escogida al azar como la variable respuesta y el resto de variables son "resumidas"usando an�lisis de componentes principales (PCA) para disminuir colinearidad. La funci�n devuelve la proporci�n de r�plicas que produjeron al menos una variable con un efecto significativo (osea falsos positivos).
#
# La simulaci�n pretende representar un an�lisis de datos com�n cuando se trabaja con m�ltiples variables respuesta donde no se tiene conocimiento a priori de cuales variables pueden incidir en la variable respuesta (o donde se deja a un algoritmo escogerlas sin darle mucha cabeza al problema). 
#
# El procedimiento de regresi�n escalonada siga al pie de la letra el procedimiento descrito en "https://www.statology.org/stepwise-regression-r/".
#
# Argumentos:
# itr: numero de iteraciones o replicas (el valor por defecto es 100)
# nvars: numero de variables para representar (el valor por defecto es 50)
# n: n�mero de observaciones en cada variable (el valor por defecto es 30)
# alpha = umbral para definir significancia estad�stica en los valores de p

replicar_reg_scal <- function(itr = 100, nvars = 50, n = 30, alfa = 0.05){
  
  # replicar itr veces
  valores_p <- replicate(n = itr, expr = {
    
    # crear n variables al azar desde una distribuci�n normal
    datos <- replicate(n = nvars, expr = rnorm(n = n, mean = 0, sd = 1))
    
    # escoger al azar una variable como respuesta
    resp_indc <- sample(ncol(datos), 1)
    resp <- datos[, resp_indc]
    
    # remover respuesta de datos
    datos <- datos[, -resp_indc] 
    
    # usar componentes principales para lidear con colinearidad y mantener las 10 
    pca <- prcomp(datos, scale. = TRUE)
    
    # extraer la contribucion de los PC's
    pca_summ <- summary(pca)$importance
    
    # determinar cuantos PC's se deben usar para incluir al menos 70% de la variacion el los datos
    max_pcs <- which.max(pca_summ[3, ] > 0.7)
    
    # extraer PC's escogidos y convertir a data.frame y 
    datos_pca <- as.data.frame(pca$x[, 1 : max_pcs])
    
    # definir un modelo nulo (sin predictor)
    mod_nulo <- lm(resp ~ 1, data = datos_pca)
    
    # definir modelo global
    mod_global <- lm(resp ~ ., data = datos_pca)
    
    # correr regression escalonada
    mod_final <- step(mod_nulo, direction = 'both', scope = formula(mod_global), trace = FALSE)
    
    # extraer coeficientes
    sm <- summary(mod_global)
    
    # extraer y devolver valores de p excluyendo el del intercepto
    sm$coefficients[-1 , 4]
    
  })
  
  # calcular cuantas variables produjeron un valor de p menor a alfa para cada iteracion 
  signf <- sapply(valores_p, function(x) sum(x < alfa))
  
  # calcular el numero de iteraciones con al menos una variable significativa
  sig_itr <- sum(signf > 0) / itr
  
  return(sig_itr)
}

# ejemplo:
falsos_positivos <- replicar_reg_scal(itr = 100, n = 30, nvars = 100, alfa = 0.05)
# 
falsos_positivos

