{-# LANGUAGE MultiParamTypeClasses, FlexibleContexts, ScopedTypeVariables, TypeSynonymInstances, FlexibleInstances #-}
module Cloudshell where
import qualified Data.Map as M
import Transient.Internals hiding (read1, fork)
import Transient.Indeterminism
import Transient.Move.Internals
import Transient.Move.Utils
import Transient.Move.Services
import Transient.Logged
import Data.IORef
import Control.Applicative
import Control.Monad.IO.Class
import System.Directory
import System.Process hiding(readCreateProcess)
import qualified System.Process as SP(readCreateProcess)
import Data.List
import Control.Exception hiding (onException)
import Unsafe.Coerce
import Data.Typeable
import System.Random
import System.IO.Unsafe
import System.IO
import Control.Monad
import System.FilePath
import System.Exit
import Data.Hashable
import Network.HTTP
import Data.Maybe
import Data.Monoid
import Control.Concurrent
import qualified Data.ByteString.Char8 as BS 
import Debug.Trace
{-

  A shell for composing applications.
  component results: paths (logs) and streams | Empty
  
  main= input >> processing >> output

  main in out= do 
       choose $ read $ readLine in 
       r <- process
       writeline out

  shell operators pipe ::  >>=
                   a <|> b : execute a and b

  variables of the shell are streamns

  comp a b= comp operating over streams a and b 

  como definir el interface de un componente: en un fichero

  tiene sentido? transient ya permite definir componentes
  streams pueden atravesar nodos
    Pero no se puede compartir scopes/closures
    el problema de programar con pipes es que no acepta control de flujo/inyección de eventos
      es un control lineal.
      además un solo punto de entrada y una sola salida
  
 vieja idea de un sistema de componentes que permite docking sin docker 

    State -> Components -> NewState 

     construccion va por un lado y ejecucion por otro (como en FRP)

     en transient shell y en un shell construccion y ejecución son lo mismo,

  un sheel de ese tipo: 
        busca los componentes en la cloud y los ensambla antes de ejecutarlos
        los ensambla en distintos nodos si hay distributed computing 
        maneja logs como transient 
        ensambla componentes con operadores 


contennt of decscruotion:
name: programname
executable: execName
interface: file, host-port
Signature: Haskell signature
install: shell to install it
   must return extra parameters: host, port, executable
   they are added to the description.
   the description is thus mutable
   the installation can execute a Dockerfile

service monitor    --must
executable monitorService   
package https://github.com/transient-haskell/transient-universe
image
install <url csh script>

initializacion   expresion con $host  $port

access:  con transient (node), 
         host-port con una estructura 
         REST  GET POST (expression con $host $port $parameters)
         executable one time 

url
host
port
execution  $1 $2 


algoritmo= do 
  buscar invocation invocar 
         si invocation is con REST 
              componer URL 
              invocar
              extraer valores con read
         si invocation con exe 
              componer linea de comando
  si falla
  buscar ejecutable
  si existe,  si tiene initialization, initialize

  si no existe install local o remoto llamar a monitor >> algoritmo




distribucion y escalado

how to verify signature 
   Int -> String ->  Int
aparecer a haskell como de ese tipo
con un stub haskell (strong typing)
con showable arguments (may allow to construct stub above)


Como recojer respuestas:
    install:  extra parameters
    execute: response

    si son shell programs, el standard output
    createProcess get standard output >> return . read

    image docker: y es servicio o install 
       invoca remoto el host y port y lo da de alta
       continua en ese nodo.
    image docker y no es servicio o install:
      ejecuta lo actual

      distinguir:
       install
       init 
       invoke

       image:: cambiar de una imagen a ejecutar todos los demas comandos en esa imagen
         virtual: docker run image -v asignado al directorio actual -p asignado automaticamente

 invoke expr varios parametros
    opcion almacenarlos en un map
    invoke expr $ args 1 2 3 4
    por que no aplicarlo directamente????

escalado de instancias: con parametros
    manifest puede tener varios host-port
repartir la carga entra varios nodos
   considerar todos los nodos en getNodes
   mover servers a otors nodos?
   cuando es un server, elegir el nodo, no hace falta local
     medir carga y migrar servicios:
       description en cada nodo
       un proceso mide cargas de cada nodo
       migra servicios

como instalar un servidor que depende de otro? 
   p ej. una web app que depende de una base de datos?
   dependency?
     como se pasan parametros de una dependencia para invocarla
       dependencia de ejecutable - no hay problema
       dependencia de servicio transient: resuelta por el servicio mismo
       dependencia de servidor: 
          si el cliente es ejecutable: necesita probablemente el host y port
          detectar que es un servidor: y pasarle host y port
             como se pasan los parametros?
                 hay que pasarlos internamente:
                 
                   invoke  program $databaseHost $databasePort
                   dependency databasemanifest.file  databaseHost databasePort
                 
                 y si la dependencia es un fichero o un pipe?
                 codificar tipo de parametro en nombre:  $pipesufijo  $hostsufijo  $portsufijo
                   asi el shell puede preasignar tanto a programa como a dependencia
                   por tanto un manifest que puede usarse como dependencia debe declarar variables
                   "variables" tag?

          una vez instalada la dependencia, retornar las variables definidas dentro
             por ejemplo si manifest de ejecutable menciona variable $hostDatabase $portDatabase
               dependency: database ¿como se obtiene autmaticamente esas varaibles?

save/recovery

invoke:  una linea de comando
 si es una linea: asumir que equivale a invoke

deoendencias:
  un programa puede depender para su instlacion de una cosa y para su ejecucion de otra.
  como se gestiona eso?
    installdependency
    initdependency
    invokedependency
    ejecutable -> depedencia

    manifest es una secuencia de ejecuciones y dependencias con variables.
    se ejecutan en orden inverso. usar onException para hacer backtracking

    exe `dependsOn` cabal
    codificar en Haskell? no en fichero:

    problema: la lista de dependeicias no es una sequencia preestablecida.
      cada paquete tiene que establecer su nivel inmediatamente superior de dependencias

otra opcion: visualizar jobs parados

nueva feature: ejecutar directametne scripts que podran tener url paths.
  en el preprocesado, se descargan esas URLS

nueva feature:  make = change con fecha  
aplicacion ejemplo : compilar en diferentes maquinas con diferentes versiones de ghc
  url <- change "static" >>=  generateURL "url" 
  result <- invokec "image haskell:8.0.2\ncabal install $url && echo succces"  <> 
            invokec "image fpco/stack-build\nstack build $url && echo success" -- usa todos los nodos

  procesar

Algoritmo general:
  si al ejecutar falta una variable sin inicializar
     $host $port  -> install, init
     otra: $var-component   -> instalar package, init
     variable local -> error

     error ejecución : ver variables que intervienen 
        
     Algoritmo install-init-run:
  si al ejecutar  replaceVars falta una variable sin inicializar
     $host $port  -> asignar

     otra: $var-component   ->
                 y si ya esta instalado?
                 buscar variable, si no existe, instalar ese compoente
                  por ejemplo: host port
                  normalmente variables usadas son el resultado de instalacion
                  pero que hay de shells que necesitan ejecutables sin variables?
                       scanear ejecutables e insalarlos?
                       NO, MANTENER dependencias explicitas: dependency tag
     variable local -> error

  si hay init, ejecutarlo


continuos integration:
  file <- depend [file1,file1, file3]
  compile file
  link

funcionalidad: ver el log online de cada invoke

puede usarse exceptions para implementar ParAlternative?

pempty =back PAlternative

mx <||> my= mx `onBack` (\PAlternative) -> comtinue >> my

ventajas: funciona con cualqier thread en mx

puede implementar alternative? si se detecta WasParallel
pero backtracking necesita empty

requires: "check" keyword for a script that return boolean if exist or not.
  return something to the caller to inform if there is no way to install it.
-}

data PAlternative= PAlternative deriving (Show, Typeable)

pempty =back PAlternative

Cloud mx <||> Cloud my= Cloud $ mx `onBack` (\(_ ::PAlternative) -> continue >> my)

fork task=  (abduce >> task >> empty) <|> return ()

forkc task= (local abduce >> task >> empty) <|> return ()


configurations= unsafePerformIO $ newIORef M.empty :: IORef(M.Map String Manifest)

testmanifest=
    "name nameofmanifest\n\
    \service monitor\n\
    \executable monitorService\n\
    \package https://github.com/transient-haskell/transient-universe\n\
    \image\n\
    \install misma que invocation\n\
    \init  initialization\n\
    \invoque program $1pipe $2\n\
    \dependency manifest.csh  "  -- http:// .... host port"
     
 

toMap :: String -> [(String, String)]
toMap desc= map break1 $ lines desc
 where
 break1 line=
    let (k,v1)= break (== ' ') line
    in (k,dropWhile (== ' ') v1)


emptyIfNothing' mx= emptyIfNothing mx <|> pempty

type Manifest= [(String, String)]

invoke3 desc arg1 arg2 arg3= do

    if length (lines desc)== 1 && not ( ".csh" `isSuffixOf` desc) then do
        local $ execShell (subst desc arg1 arg2 arg3) ""  !> "INVOKE3 LINES=1"
      else do

          desc <- localIO $  if ".csh" `isSuffixOf` desc then readFile desc 
                                                         else return desc
          let map=  toMap $ subst desc arg1 arg2 arg3
          name <- localIO $  return (lookup "name"  map) `onNothing`  newName
          mp  <-  localIO $ readIORef configurations >>= return . M.lookup name :: Cloud (Maybe Manifest)
          when ( mp == Nothing) $ do
             localIO $ modifyIORef  configurations  $ \configs -> (M.insert name map configs)
             -- dependencies name
             -- substVars name

          invoke name


invoke2 desc arg1 arg2= do
    if length (lines desc)== 1 && not ( ".csh" `isSuffixOf` desc) then do
        local $ execShell (subst desc arg1 arg2) ""   !> "INVOKE2 lines=1"
      else do
          desc <- localIO $  if ".csh" `isSuffixOf` desc then readFile desc else return desc

          let map=  toMap $ subst desc arg1 arg2 
          name <- localIO $ return (lookup "name"  map) `onNothing` newName
          mp  <-  localIO $ readIORef configurations >>= return . M.lookup name :: Cloud (Maybe Manifest)
          when ( mp == Nothing) $ do
             localIO $ modifyIORef  configurations  $ \configs -> (M.insert name map configs)
             -- dependencies name
             -- substVars name

          invoke name

invoke0 :: Loggable a => String -> Cloud a
invoke0 desc= do
   if length (lines desc)== 1 &&  not ( ".csh" `isSuffixOf` desc) then do
        local $ execShell  desc ""    !> "INVOKE0 lines=0"
      else do
          return () !> ("invoke00", desc)
          desc <- localIO $  if ".csh" `isSuffixOf` desc then readFile desc else return desc

          let map=  toMap  desc
          name <- localIO $ return (lookup "name"  map) `onNothing`  newName
          mp  <-  localIO $ readIORef configurations >>= return . M.lookup name :: Cloud (Maybe Manifest)
          when ( mp == Nothing) $ 
             localIO $ modifyIORef  configurations  $ \configs -> (M.insert name map configs)
             -- dependencies name
             -- substVars name

          invoke name !> ("invoke", name)

newName= liftIO $  (++) <$> return "noname" <*>  (show <$> randomRIO (0,100000 :: Int))


requirementsFor deptype name= do
   dependencies deptype name
   substVars name
  where
  dependencies :: String -> String -> Cloud ()
  dependencies deptype name= do 
      return () !> deptype
      map1 <- localIO $ (readIORef configurations >>= return . M.lookup name) `onNothing` error name
      let deps= map snd $ filter ( (==)  deptype . fst ) map1
      
      mapM_ invoke' deps 
      where
      invoke' x= do
        local $ do cutExceptions ; onException $ \(e :: IOException) -> liftIO $ print $ "manifest not found for " ++ x
        invoke0 (x ++ ".csh") :: Cloud ()
            
  substVars name = local $ do
      map  <-  liftIO (readIORef configurations >>= return . M.lookup name) `onNothing` error name
      map' <- mapM replaceVars' map :: TransIO Manifest
      liftIO $ modifyIORef  configurations  $ \configs -> (M.insert name map' configs)
      where
      replaceVars' ::    (String,String) -> TransIO (String,String)
      replaceVars' (k,v)=do
        v' <- replaceVars v
        return (k,v') 

invoke1 desc arg= do
     if length (lines desc)== 1 && not ( ".csh" `isSuffixOf` desc) then do
        local $ execShell (subst desc arg) "" !> "INVOKE1 LINES=1"
      else do
          desc <- localIO $  if ".csh" `isSuffixOf` desc then readFile desc else return desc
          let map=  toMap $ subst desc arg
          name <- localIO $ return (lookup "name"  map) `onNothing`  newName
          mp  <-  localIO $ readIORef configurations >>= return . M.lookup name :: Cloud (Maybe Manifest)
          when ( mp == Nothing) $ do
             localIO $ modifyIORef  configurations  $ \configs -> (M.insert name map configs)
             -- dependencies name
             --substVars name

          tryDockerService name arg <|> tryService name arg <|> invoke name

  

  where
  tryService name arg= do
      map <- localIO $ (readIORef configurations >>= return . M.lookup name) `onNothing` error name
      local $ emptyIfNothing $ lookup "service" map
      callService  map arg

  tryDockerService  name arg= loggedc $ do
      conf    <- localIO $ (readIORef configurations >>= return . M.lookup name ) `onNothing`  error "noname"
      image   <- local $ emptyIfNothing $ lookup "image" conf
      service <- local $ emptyIfNothing $ lookup "service" conf
      
      path <- local $ Transient $ liftIO $ findExecutable "docker"    -- return empty if not found
  
      port <- localIO freePort
      host <- local $ nodeHost <$> getMyNode -- localIO $ readProcess "docker-machine" ["ip"] ""
      monitorNode <- localIO $ createNodeServ host port monitorService
      local $ addNodes [monitorNode]
      localIO $ callProcess path [subst "run  -p $3:3001  $1 monitorService -p start $2/$3" image host port]
      nodes <- callService'  monitorNode ("ident",conf,(1 :: Int))
      local $ addNodes nodes
      callService conf arg


newtype InvokeList= InvokeList (M.Map String EventF) deriving Typeable

invoke name= loggedc $  do
   checkpoint' name
   pr <- localIO $ show <$> ( randomRIO (1,100000 :: Int))
   copyData $ ProcessLog pr
   map <- localIO $ (readIORef configurations >>= return . M.lookup name) `onNothing` error name  
   case lookup "image" map of
      Nothing -> installExecute name
      Just _  -> tryDocker name
   -- tryDocker name <||> installExecute name  
  where
  checkpoint' name= local $ do
    cont <- getCont 
    InvokeList map <- getRState  <|>  return (InvokeList (M.empty))
    setRState $ InvokeList $ M.insert name cont  map
    dir <- liftIO getCurrentDirectory
    
    liftIO $ do
      let ndir=  dir ++"/logs/" ++ name
      logsExist <- doesDirectoryExist  "logs"
      when (not logsExist) $ createDirectory "logs"
      createDirectory ndir
      setCurrentDirectory ndir
      dir' <-  getCurrentDirectory
      return () !> ("checkpoint",dir')
    checkpoint
    liftIO $ setCurrentDirectory dir

  installExecute name = do
     requirementsFor "invokedep" name
     retries <- onAll $ liftIO $ newIORef (0 :: Int)   
     local $ onException $ \(_:: SomeException) -> do
          r <- liftIO $ readIORef retries
          if r < 3 then  do liftIO $ writeIORef retries (r+1); continue else return ()
     map <- localIO $ (readIORef configurations >>= return . M.lookup name) `onNothing` error name 

     let mexe = lookup  "invoke" map 
     case mexe of
          Nothing   -> do installShell name ; installExecute name 
          Just expr -> local $ exec1  expr   


     where
     rest= error "REST not implemented yet"
     exec1 expr | "http" `isPrefixOf` expr=  rest expr 
                -- | POST¿? en http
                | otherwise=  execShell expr ""  !>  "INSTALLEXECUTE"
                    

execShell expr input=  do
     let createprostruct= shell expr 
     resp <- readCreateProcess createprostruct input !> ("EXECSHELL",expr)
     return $ read1 resp

read1  str= x 
 where
 x=
   let typeofx = typeOf x
   in if typeofx /= typeOf  ( undefined :: String) then read str else unsafeCoerce str

installShell name=  do
      requirementsFor "installdep" name
      conf  <- localIO $ (readIORef configurations >>= return . M.lookup name) `onNothing` error name

      shellexp <- local $ emptyIfNothing $ lookup "install" conf
      let createprostruct= shell  shellexp 
      nconf <-   local $ readCreateProcess  createprostruct ""
      localIO $ modifyIORef  configurations   $ \configs -> M.insert name (conf++ read nconf) configs

{-
   image docker: y es servicio o install 
       invoca remoto el host y port y lo da de alta
       continua en ese nodo.
    image docker y no es servicio o install:
      ejecuta lo actual
-}

tryDocker name =  do

      conf    <- localIO $  (readIORef configurations >>= return . M.lookup name) `onNothing` error name
      image   <- local $ emptyIfNothing $ lookup "image" conf
      let init     = lookup "init" conf  -- if no init, it is not a server process

      case init of
        Nothing -> dockerProgram name image 
        Just _ -> dockerService name  image 
    where

    
    dockerService rconf image= tryInvoke rconf image  <|> (installDockerService rconf  >> dockerService rconf image)

    tryInvoke name image =  do

      requirementsFor "invokedep" name
      conf  <- localIO $   (readIORef configurations >>= return . M.lookup name) `onNothing` error name

      local $ do
        invoke  <- emptyIfNothing $ lookup "invoke" conf
        port    <- emptyIfNothing $ lookup "port" conf  -- try to find  the port if not, it has not been installed
        host    <- emptyIfNothing $ lookup "host" conf  -- then istall it with installDockerService
        let invoke'= replaces (replaces invoke "$host" host) "$port" port
        execShell  invoke' ""   !>"TRYINVOKE"
 

    installDockerService name  = do
      node <-  randNode
      requirementsFor "initdep" name
      conf <- localIO $   (readIORef configurations >>= return . M.lookup name) `onNothing` error name

      init <- local $ emptyIfNothing $ lookup "init" conf  -- if no init, it is not a server process

      nconf <- runAt node $ local $ do
        -- host must be the one of the node. port must be mapped
        port <- freePort
        host <- nodeHost <$> getMyNode -- liftIO $ readProcess "docker-machine" ["ip"] ""
        work <-liftIO $ makeAbsolute "work" 
        let work'=  replace " " "\\ " $ replace "\\" "/" (replace "C:" "/c" work) 
        execShell  (subst "docker run -v $3:/work -it -p $3000:$1  $2"  port init work') "" !> "INSTALLDOCKERSERVICE" :: TransIO ()
        return $  [("host",host), ("port", show port)]

      localIO $ modifyIORef  configurations   $ \configs -> M.insert name (conf++nconf) configs

    randNode= local $ do
      nodes <- getNodes
      n <- liftIO $ randomRIO (0,length nodes-1)
      return $ nodes !! n
    -- dockerProgram :: (Subst1 t1 t, Show t, Show a, Typeable b, Read b) =>
    --                IORef [([Char], [Char])] -> a -> t1 -> TransIO b
    dockerProgram name image  =  do
      node <-  randNode
      wormhole node $ do
       copyData $ LocalVars M.empty 
 
       atRemote $ do 
        requirementsFor "invokedep" name
        conf <- localIO $ (readIORef configurations >>= return . M.lookup name) `onNothing` error name
        local $ do
          program <- emptyIfNothing $ lookup "invoke" conf <|> return ""
          work <-liftIO $ makeAbsolute "static/work" 
          let work'= replace " " ('\\':" ") $ replace "\\" "/" (replace "C:" "/c" work) 

          let command=  subst "docker run -t -v $3:/work $1  bash -c $2 " image (show $ "cd work && "++ program) work'
          execShell  command "" !>("DOCKERPROGRAM", command)
   





changed ::  String -> Int -> TransIO String
changed shellexp interval=  do
    let action= SP.readCreateProcess   (shell shellexp)  "" 
    v <- liftIO action
    prev <- liftIO $ newIORef v 
    files <- waitEvents (loop action prev) 
    choose files
    where 
    loop action prev = loop'
            where loop' = do
                    threadDelay $ interval * 1000000
                    v  <- action
                    v' <- readIORef prev 
                    if v /= v'  then writeIORef prev v >> return (lines v \\ lines v') else loop'

 -- `catcht`  \(e :: SomeException) -> liftIO $ putStr "changed: " >> print e


class Subst1 a r where 
    subst1 :: String -> Int -> a -> r

instance (Show a,Typeable a) => Subst1 a String where
     subst1 str n x= subst2 str n x 
       
subst2 str n x=  replaces str ('$' : show n ) x

replaces str var x= replace var (show1 x) str  

replace _ _ [] = []
replace a b s@(x:xs) = 
                   if isPrefixOf a s
                            then b++replace a b (drop (length a) s)
                            else x:replace a b xs

-- | find all patterns and susbtitute the string wiht the result of a function.
replacet :: String -> (String -> TransIO(String,String)) -> String -> TransIO String
replacet  pattern fun str= rep str
  where
  rep  [] = return []
  rep  (s@(x:xs)) = 
        if isPrefixOf pattern s
              then do (b,s') <- fun s; (++) <$> return b <*> rep  s'
              else (:)  <$> return x <*> rep  xs


instance (Show b, Typeable b, Subst1 a r) => Subst1 b (a -> r) where
    subst1 str n x = \a -> subst1 (subst1 str n x) (n+1) a 

replaceVars :: String -> TransIO String
replaceVars []= return []
replaceVars ('$':str)= do
   LocalVars localvars <- getState <|> return (LocalVars M.empty)
   let (var,rest')= break (\c -> c=='-' || c==' ' || c == '\n' ) str
       (manifest, rest)= if null rest' || head rest'=='-' 
            then  break (\c -> c =='\n' || c==' ') $ tailSafe rest'
            else  ("", rest')

   if var== "port"&& null manifest then (++) <$> (show <$> freePort) <*> replaceVars rest   -- $host variable
   else if var== "host" && null manifest then (++) <$> (nodeHost <$> getMyNode) <*> replaceVars rest
   else if null manifest  then
      case M.lookup var localvars of
          Just v -> do 
              v' <- processVar v
              (++) <$> return (show v') <*> replaceVars rest
          Nothing -> (:) <$> return '$' <*> replaceVars rest 
   else do
      map <- liftIO $ readFile manifest >>= return . toMap
      let mval = lookup var map 
      case mval of 
        Nothing -> error $ "Not found variable: "++ "$" ++ var ++ manifest 
        Just val -> (++) <$> return val <*> replaceVars rest
   where
   tailSafe []=[]
   tailSafe xs= tail xs

   processVar :: String -> TransIO String
   processVar v 
     | "http://" `isPrefixOf` v =  do 
          requires  ["curl","tar"]
          filename <- emptyIfNothing $ stripExtension "tar.gz" $ snd $ splitFileName v
          exist <- liftIO $ doesDirectoryExist $ "./static/work/"++filename !> ("filename",filename)
          -- when  (not exist) $ do
          --      let cmd=  subst "curl $1 | tar xz -C work "  v
          --      void $ readCreateProcess  (shell cmd) "" !> ("cmd",cmd)
          return  filename

     | otherwise= return v



replaceVars (x:xs) = (:) <$> return x <*> replaceVars xs


subst :: Subst1 a r => String -> a -> r
subst expr= subst1 expr 1

data LocalVars = LocalVars (M.Map String String) deriving (Typeable, Read, Show)
instance Loggable LocalVars

newVar :: (Show a, Typeable a) => String -> a -> TransIO ()
newVar  name val= noTrans $ do 
   LocalVars map <- getData `onNothing` return (LocalVars M.empty)
   setState $ LocalVars $ M.insert  name (show1 val) map
  
show1 x | typeOf x == typeOf (""::String)= unsafeCoerce x 
          | otherwise= show x

generateURL :: String -> TransIO String
generateURL path= do
    n <- getMyNode
    return $ "http://" ++ nodeHost n++ ":"++ show (nodePort n) ++ "/"++  path
    

type MBoxId= String

type Url= String
type IdProcess= String
type IdGroup= String
type ProcessEntry= (Node,IdGroup, IdProcess,Url)
data ProcessLog = ProcessLog  MBoxId  deriving (Typeable,Read,Show)

instance Loggable ProcessLog

readCreateProcess proc _ = do
   onException $ \(e :: SomeException) -> liftIO $ print e
   (_, Just out,Just err,ph) <- async $ createProcess $  proc{std_out = CreatePipe,std_err = CreatePipe}
   let ShellCommand str= cmdspec proc
   labelState $ BS.pack str 
   return () !> "READCREATEPROCESS"
   ProcessLog processes <-  getState <|>  error "NO PROCESSLOG"
   let idProcess = processes ++ show (hash str)
       fileLog= "./static/out.jsexe/"++idProcess++".log"
   
   fork $ do   
      url <- generateURL $ idProcess ++ ".log"
      return () !> ("URL", url)
      node <- getMyNode
      putMailbox' "processes"  (node,str,idProcess,url)
      saveLog str fileLog out err  idProcess 
      
   code <- liftIO $ waitForProcess ph
   putMailbox' idProcess (Left code :: Either ExitCode String)
   when (code /= ExitSuccess) $ throwt code
   liftIO $ readFile fileLog
 where
 saveLog str fileLog out err  idProcess= do
   onException $ \(e :: IOError) -> liftIO $ do  putStr "saveLog: " ;print e; hClose out; hClose err
   liftIO $ appendFile fileLog ("\nLog for "++ str ++ "\n")
   
   str  <- liftIO $ hGetContents out
   str' <- liftIO $ hGetContents err
   line <- threads 0 $ (choose $ lines str) <|> (choose $ lines str') 
   liftIO $ appendFile fileLog ('\n':line)
   
   putMailbox' idProcess  (Right line :: Either ExitCode String)
   

showLog  =  do
          menun <- lazy $ liftIO $ newIORef (1 :: Int)
  
          local $ setRState $ JobGroup M.empty
          
          (node,str,idProcess, url :: String) <- clustered $ local $ getMailbox' "processes" :: Cloud  ProcessEntry

          local $ do
             n <- liftIO $ atomicModifyIORef menun $ \n -> (n+1,n)    
             oneThread $ option  ("l"++show n) str
          last1 <- local $ do
             log <- liftIO $ simpleHTTP (getRequest  url) >>=  getResponseBody 
             liftIO $ putStrLn log
             return $ last $ lines log 

          case last1  of
             "Status: ExitSuccess" -> return ()
             _ -> do  
                  mln <- wormhole node $ do
                          stopRemoteJob $ BS.pack"streamlog"
                          atRemote . local $ getMailbox' idProcess 
                  localIO $ putStrLn mln




   -- un proceso en un nodo puede haber fallado, pero otros nodos estan corriendo
   -- hay que matar todos y usar sus logs para reanudar.
   -- alternativamente se puede reanudar el nodo que falla.
   --   en ese caso habria que almacenar (nombre, executable, log) O almacenar log en csh?
   --   desarrollar separadamente fuera de cloudshell.
   --   restartable  :: Cloud a -> Cloud a



  {-
  codificar lo que tiene instalado cada nodo: en services con key "installed"
  siguiente: probar dependencuas
       ejemplo

  codificar depends

  requires exige en todos los nodos

codificar save state, show stopped jobs-causes, retry
    cuando es error en otro nodo? poner nodo-causa  
  restore remote job
  online:  save remote continuation in a Restore name cont
           pero tiene que continuar la computacion distribuida actual
              el job remoto puede hacer retry
                 restartableRunAt node xxx
                 restartable job= do
                    cd jobname
                    r <- restore job job
                    case r of
                       Left err -> do
                            r <- whattodo
                            if r then  job
                            else retunn left err
                       Right r -> return r
                
         whattodo=  if master then option else atRemote whattodo

              o puede reejecutar el principal.
                 pero eso exige eliminar los actuales que estaban corriendo

obtener dependencias de un Dockerfile?
ejecutar desde el final, si da error, ejecutar el anterior no ejcutado
   
  -}


restartable :: Loggable a => String -> Cloud a  -> Cloud(Either String a)
restartable  jobname job= do
    localIO $ do
        r <- doesDirectoryExist jobname
        when  r $ removeDirectoryRecursive jobname
        createDirectory  jobname  
        setCurrentDirectory jobname
    restorable job
    where
    restorable job= restore' $ do
     r <- (Right <$> job) `catchc` \(e :: SomeException) -> return . Left $ show e
     case r of
       Left err -> do
            node <- local getMyNode
            (r,n) <- atConsole $ \n  -> do 
              let n= 0 :: Int
              let shown= show n
              liftIO $ do putStrLn $ "---- job "++ show n ++ " error ----\n"
                          putStrLn err
                          putStrLn "\nat node: ";
                          print node
                          putStrLn "\n---- end error ----\n"

              r <-   option (shown ++ "-cont"  ) "continue execution if you had solved the problem on the node" <|>
                     option (shown ++ "-cancel") "cancel"

              return $ (drop (length shown +1 ) r,n) 
            localIO $ print r
            case r of
              "cont"   -> restorable  job
              "cancel" -> localIO $ do 
                   print  $ "job " ++ show n ++" cancelled"
                   return $ Left err 
              
       Right r -> return $ Right r
   
catchc :: (Loggable a,Exception e) => Cloud a -> (e -> Cloud a) -> Cloud a
catchc (Cloud c) ex= Cloud $ logged $ c `catcht` \e ->  runCloud' $ ex e 

restore' :: Cloud a -> Cloud a
restore' (Cloud job)= Cloud $ do
    liftIO $ print "RESTORE"
    restore job  

data Console = Console Node Int deriving (Typeable, Read, Show)

rconsole= unsafePerformIO $ newEmptyMVar

atConsole :: Loggable a => (Int -> TransIO a) -> Cloud a
atConsole todo= do
  
  mconsole <- localIO $ tryTakeMVar rconsole
  case mconsole of
    Just (Console node n) ->  runAt node $ local $ todo n -- do local $ setRState (Console $ n +1); local $ todo n
    Nothing ->  empty  !> "NO CONSOLE" -- atCallingNode $ atConsole todo  !> "NOT IN CONSOLE"
       

(!!>) x y = (flip trace ) x (show y)   


main1 = keep $ runCloud'  proc
  where
  proc= restore' $ do
      localIO $ print "main"
      r <- (Right <$> job) `catchc` \(e :: SomeException) -> return . Left $ show e
      case r of
        Left err -> do
            localIO $ print err
            proc
      return()
  
  job= do
     localIO $ print "RUNNING"
     error "error1"
     return ()

main= keep  . initNode $ inputNodes  <|> process
    where
   
    process= do
        node <-  local getMyNode
      
        clustered $ localIO $ putMVar rconsole $ Console node 0
      
      
        local $ onException $ \(e:: SomeException) -> liftIO $ print e
--      forkc showlog
      
     -- runAt node $ do
        pr node "hello"  -- <|> pr node "world"
        return ()
        where
        showlog= do
               (node,msg) <- clustered $ local $ getMailbox' "jobs" :: Cloud (Node,String)
               local $ option msg msg
               
               r <- wormhole node $ do
                       stopRemoteJob "streamlog"
                       atRemote $ local $ getMailbox' msg !> ("getmailbox", msg)
               localIO $ putStrLn r
               
        pr node msg=  runAt node $  do
             restartable  "job" $ local $ do
           --    node <- getMyNode
           --    putMailbox' "jobs" (node, msg)
           --    setRState (1 :: Int)
           --    r <-  choose (repeat msg) 
           --    liftIO $ threadDelay 1000000
            --   putMailbox' msg msg
            --   n <-  getRState
            --   liftIO $ print n
               liftIO $ print "EXECUTING"
               error "break" -- if (n `rem` (10 :: Int)) ==0 then error "break" else setRState (n +1) 
               empty
               return ()
    
    
    process1=   do
         return () !> "process"
         requires ["ls","docker"]
         let folder= "dropfolder"
         local $ do
            file <- changed ("ls  static/out.jsexe/" ++ folder) 3 
            return () !> "FILE"
            url <- generateURL $ folder ++ "/"++ file
            return () !> ("URL", url)
            newVar "url" url
         localIO $ print "NEW FILE"
         result <- invoke0 "image typelead/eta\ninvoke cd $url && etlas install directory-1.3.1.0 && etlas install && echo success"   
                   <> invoke0 "image agocorona/transient:01-27-2017\ninvoke cd $url && cabal update && cabal install && echo success"    -- use all the nodes
         
         localIO $ putStrLn result
         
requires _= return ()
    
requires1 rqs= local $ do
       nodes <- getNodes
       setState $ filter hasreq  nodes
       where
       hasreq node=  
          let srvs= nodeServices node
              insts= map snd $ filter ((==) "installed" . fst) srvs
          in  null $ rqs \\ insts 