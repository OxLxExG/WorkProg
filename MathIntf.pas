unit MathIntf;

interface

uses System.SysUtils;

type

  EMatLabException = class(Exception);

  ILastMathError = interface
  	function GetLastError(out err: PAnsiChar): HRESULT; stdcall;
  end;

  PRbfReport = ^TRbfReport;
  TRbfReport = record
   arows: integer;
   acols: integer;
   annz: integer;
   iterationscount: integer;
   nmv: integer;
   terminationtype: integer;
  end;

  IRbf = interface(ILastMathError)
 	  function Create(nx, ny: Integer): HRESULT; stdcall;
  	function Points(const xy: PAnsiChar): HRESULT; stdcall;
   	function Term(t: Integer): HRESULT; stdcall;
  	function AlgoQNN(q: Double; z: Double): HRESULT; stdcall;
  	function AlgoMultilayer(rbase: Double; nlayers: Integer; lambdav: Double): HRESULT; stdcall;
   	function Build(out res: PRbfReport): HRESULT; stdcall;
    function Calc2(x0, x1: Double; out res: Double): HRESULT; stdcall;
    function Calc3(x0, x1, x2: Double; out res: Double): HRESULT; stdcall;
  end;

  PPolynomialFitReport = ^TPolynomialFitReport;
  TPolynomialFitReport = record
    taskrcond, rmserror, avgerror, avgrelerror, maxerror: Double;
  end;

  IBaryCentric  = interface(ILastMathError)
 	  function Fit(const x, y: PAnsiChar; m: Integer; var info: Integer): HRESULT; stdcall;
 	  function FitWc(const x, y, w, cx, cy, cd: PAnsiChar; m: Integer; var info: Integer): HRESULT; stdcall;
 	  function FitV(const x, y: PDouble; Len, m: Integer; var info: Integer): HRESULT; stdcall;
    function GetY(x: Double; var y: Double): HRESULT; stdcall;
    function GetLastFitReport(out Rep: PPolynomialFitReport): HRESULT; stdcall;
    function GetLastPow2(var pow: PDouble): HRESULT; stdcall;
  end;

  PComplex = ^TComplex;
  TComplex = record
    x,y: Double;
  end;

  IFourier  = interface(ILastMathError)
 	  function fft(const x: PDouble; Len: Integer): HRESULT; stdcall;
 	  function ifft(var x: PDouble): HRESULT; stdcall;
 	  function GetLastFF(out x: PComplex): HRESULT; stdcall;
  end;

  IDoubleMatrix = interface
    function GetItem(const i, j: Integer):Double; stdcall;
    function GetRows(): Integer; stdcall;
    function GetCols(): Integer; stdcall;
    property Items[const i, j: Integer]: Double read GetItem; default;
    property Rows: Integer read GetRows;
    property Cols: Integer read GetCols;
  end;

  IClusterizer  = interface(ILastMathError)
    function SetPoints(const xy: PDouble; npoints, nfeatures, disttype: Integer): HRESULT; stdcall;
    function Ahc(algo, k: Integer; out cidx: PIntegerArray; out cz: PIntegerArray): HRESULT; stdcall;
 	  function Kmeans(restarts,  maxits, k: Integer;  out cidx: PIntegerArray; out c: IDoubleMatrix; out terminationtype: Integer): HRESULT; stdcall;
  end;

  TDoubleArray  = array[0..$0ffffffe] of Double;
  PDoubleArray = ^TDoubleArray;
  PMatrix = array of array of Double;


  PaeDynBlock = ^TaeDynBlock;
  TaeDynBlock = record
    next: PaeDynBlock;
    deallocator: TProcedure;
    ptr: Pointer;
  end;

  TaeMatrix = record
    rows: Integer;
    cols: Integer;
    stride: Integer;
    datatype: Integer;
    data: TaeDynBlock;
    ptr: Pointer;
  end;

  TaeVector = record
    cnt: Integer;
    datatype: Integer;
    data: TaeDynBlock;
    ptr: Pointer;
  end;

  PSLFittingReport = ^TSLFittingReport;
  TSLFittingReport = record
    taskrcond: Double;
    iterationscount: Integer;
    varidx: Integer;
    rmserror: Double;
    avgerror: Double;
    avgrelerror: Double;
    maxerror: Double;
    wrmserror: Double;
    covpar: TaeMatrix;
    errpar: TaeVector;
    errcurve: TaeVector;
    noise: TaeVector;
    r2: Double;
  end;

  TLSFittingCB = procedure(const c, x: PDoubleArray; out f: Double); cdecl;

  ILSFitting = interface(ILastMathError)
    function Linear(const y, fmatrix: PDouble; n, m: Integer; var info: Integer; out c: PDoubleArray; out Rep: PSLFittingReport): HRESULT; stdcall;
    function LinearW(const y, w, fmatrix: PDouble; n, m: Integer; var info: Integer; out c: PDoubleArray; out Rep: PSLFittingReport): HRESULT; stdcall;

{/*************************************************************************
Nonlinear least squares fitting using function values only.

Combination of numerical differentiation and secant updates is used to
obtain function Jacobian.

Nonlinear task min(F(c)) is solved, where

    F(c) = (f(c,x[0])-y[0])^2 + ... + (f(c,x[n-1])-y[n-1])^2,

    * N is a number of points,
    * M is a dimension of a space points belong to,
    * K is a dimension of a space of parameters being fitted,
    * w is an N-dimensional vector of weight coefficients,
    * x is a set of N points, each of them is an M-dimensional vector,
    * c is a K-dimensional vector of parameters being fitted

This subroutine uses only f(c,x[i]).

INPUT PARAMETERS:
    X       -   array[0..N-1,0..M-1], points (one row = one point)
    Y       -   array[0..N-1], function values.
    C       -   array[0..K-1], initial approximation to the solution,
    N       -   number of points, N>1
    M       -   dimension of space
    K       -   number of parameters being fitted
    DiffStep-   numerical differentiation step;
                should not be very small or large;
                large = loss of accuracy
                small = growth of round-off errors

OUTPUT PARAMETERS:
    State   -   structure which stores algorithm state

  -- ALGLIB --
     Copyright 18.10.2008 by Bochkanov Sergey
*************************************************************************/}

    function NoneLinear(const x_matrix, y, c : PDouble;  //Õ≈–¿¡Œ“¿≈“ !!! Ò Ì‡˜‡Î¸ÌÓÂ Ë„ÌÓËÛÂÚÒˇ
		                    n, m, k: Integer;
                    		diffstep, epsx: Double; maxits: integer; // conditions
                        const cLow, cHi: PDouble; // bound nil, nil - if not use
                        const cScale: PDouble; // nil - if not use

		                    cbLSFitting : TLSFittingCB;

                    		out cOut: PDoubleArray; //result
                    		out info: Integer;      //result q
                    		out Rep: PSLFittingReport): HRESULT; stdcall;

  end;
//__interface IEquations : public ILastMathError
//
//	SAFECALL LinearLS(const double *a, const ae_int_t nrows, const ae_int_t ncols, const double *b,
//ae_int_t &info, const double **x,
//double &r2, ae_int_t &n, ae_int_t &k, const IDoubleMatrix **cx);
//;

  IEquations = interface(ILastMathError)
    function LinearLS(const a: PDouble; nrows, ncols: Integer; const b: PDouble;
                      out info: Integer;
                      out x: PDoubleArray;
                      out R2: Double;
                      out n: Integer;
                      out k: Integer;
                      out cx: IDoubleMatrix): HRESULT; stdcall;

    function Linear(const a: PDouble; nrows: Integer; const b: PDouble;
                      out info: Integer;
                      out x: PDoubleArray): HRESULT; stdcall;
  end;
//  __interface ILMFitting : public ILastMathError
//
// 	SAFECALL FitV(const ae_int_t n, const ae_int_t m, const double *xin, const double *boundL, const double *boundU,
//		          const double diffstep, const double epsg, const double epsf, const double epsx, const ae_int_t maxits,
//				  void *ptr, double **xout, alglib_impl::minlmreport **Rez);
//
//
//typedef void (*Tfunc) (const double *x, double **rez);
//    ae_int_t iterationscount;
//    ae_int_t terminationtype;
//    ae_int_t funcidx;
//    ae_int_t varidx;
//    ae_int_t nfunc;
//    ae_int_t njac;
//    ae_int_t ngrad;
//    ae_int_t nhess;
//    ae_int_t ncholesky;

  PLMFittingReport = ^TLMFittingReport;
  TLMFittingReport = record
    iterationscount,
    terminationtype,
    funcidx,
    varidx,
    nfunc,
    njac,
    ngrad,
    nhess,
    ncholesky: Integer;
  end;


  TLMFittingCB = procedure(const x, f: PDoubleArray); cdecl;
  TLMFittingJacCB = procedure(const x, f: PDoubleArray; const jac: PMatrix); cdecl;

{  /*************************************************************************
Optimization report, filled by MinLMResults() function

FIELDS:
* TerminationType, completetion code:
    * -7    derivative correctness check failed;
            see Rep.WrongNum, Rep.WrongI, Rep.WrongJ for
            more information.
    *  1    relative function improvement is no more than
            EpsF.
    *  2    relative step is no more than EpsX.
    *  4    gradient is no more than EpsG.
    *  5    MaxIts steps was taken
    *  7    stopping conditions are too stringent,
            further improvement is impossible
* IterationsCount, contains iterations count
* NFunc, number of function calculations
* NJac, number of Jacobi matrix calculations
* NGrad, number of gradient calculations
* NHess, number of Hessian calculations
* NCholesky, number of Cholesky decomposition calculations
*************************************************************************/}
  ILMFitting = interface(ILastMathError)
    function FitVB(n, m: Integer; const xin, bndL, bndU: PDoubleArray; const diffstep, epsg, epsf, epsx: Double; const maxits: Integer;
                  func: TLMFittingCB; out xout: PDoubleArray; out Rep: PLMFittingReport): HRESULT; stdcall;
    function FitV(n, m: Integer; const xin: PDoubleArray; const diffstep, epsg, epsf, epsx: Double; const maxits: Integer;
                  func: TLMFittingCB; out xout: PDoubleArray; out Rep: PLMFittingReport): HRESULT; stdcall;
    function FitJ(n, m: Integer; const xin: PDoubleArray; const epsx: Double; const maxits: Integer;
                  func: TLMFittingCB; jac: TLMFittingJacCB;
                  out xout: PDoubleArray; out Rep: PLMFittingReport): HRESULT; stdcall;
    function FitJB(n, m: Integer; const xin, bndL, bndU: PDoubleArray; const epsx: Double; const maxits: Integer;
                  func: TLMFittingCB; jac: TLMFittingJacCB;
                  out xout: PDoubleArray; out Rep: PLMFittingReport): HRESULT; stdcall;
  end;

{typedef struct
	double *dwt;
	int dwt_len;
	int *length;
	int length_len;
	double flag0;
	double flag1;
 wave1d_rez_t;

__interface Iwavelet : public ILastMathError

	SAFECALL setup_dwt(const char* name, const int set_J);
	SAFECALL dw_i16(const INT16 *a, const ae_int_t cnt,  wave1d_rez_t &rez);
	SAFECALL idw(const double **x, ae_int_t &cnt);
;}
  TWaveletRez = record
    dwt: PDoubleArray;
    dwt_len: Integer;
    length: PIntegerArray;
    length_len: Integer;
    flag0, flag1: double;
  end;


  Iwavelet = interface(ILastMathError)
    function setup_dwt(const name: PAnsiChar; const J: Integer): HRESULT; stdcall;
    function dw_i16(const sig: PSmallInt; len: Integer; out rez: TWaveletRez): HRESULT; stdcall;
    function dw(const sig: PDouble; len: Integer; out rez: TWaveletRez): HRESULT; stdcall;
    function idw(out sig: PDoubleArray; out len: Integer): HRESULT; stdcall;
  end;

//__interface Ieig : public ILastMathError
{
	SAFECALL sevdi(const double *a, const ae_int_t n, const ae_int_t zneeded, const ae_int_t i1, const ae_int_t i2, bool &Res, const double **w, const IDoubleMatrix **z);
	SAFECALL sevd(const double *a, const ae_int_t n, const ae_int_t zneeded, bool &Res, const double **w, const IDoubleMatrix **z);
}

  Ieig = interface(ILastMathError)
///Subroutine for finding the eigenvalues and  eigenvectors  of  a  symmetric
///matrix with given indexes by using bisection and inverse iteration methods.
///
///Input parameters:
///    A       -   symmetric matrix which is given by its upper or lower
///                triangular part. Array whose indexes range within [0..N-1, 0..N-1].
///    N       -   size of matrix A.
///    ZNeeded -   flag controlling whether the eigenvectors are needed or not.
///                If ZNeeded is equal to:
///                 * 0, the eigenvectors are not returned;
///                 * 1, the eigenvectors are returned.
///    IsUpperA -  storage format of matrix A.
///    I1, I2 -    index interval for searching (from I1 to I2).
///                0 <= I1 <= I2 <= N-1.
///
///Output parameters:
///    W       -   array of the eigenvalues found.
///                Array whose index ranges within [0..I2-I1].
///    Z       -   if ZNeeded is equal to:
///                 * 0, Z hasnít changed;
///                 * 1, Z contains eigenvectors.
///                Array whose indexes range within [0..N-1, 0..I2-I1].
///                In that case, the eigenvectors are stored in the matrix columns.
///
///Result:
///    True, if successful. W contains the eigenvalues, Z contains the
///    eigenvectors (if needed).
///
///    False, if the bisection method subroutine wasn't able to find the
///    eigenvalues in the given interval or if the inverse iteration subroutine
///    wasn't able to find all the corresponding eigenvectors.
///    In that case, the eigenvalues and eigenvectors are not returned.
    function sevdi(const a: PDouble; n, zneeded, i1, i2: Integer;
                   out Res: LongBool; out w: PDoubleArray; out z: IDoubleMatrix): HRESULT; stdcall;
///Finding the eigenvalues and eigenvectors of a symmetric matrix
///
///The algorithm finds eigen pairs of a symmetric matrix by reducing it to
///tridiagonal form and using the QL/QR algorithm.
///
///Input parameters:
///    A       -   symmetric matrix which is given by its upper or lower
///                triangular part.
///                Array whose indexes range within [0..N-1, 0..N-1].
///    N       -   size of matrix A.
///    ZNeeded -   flag controlling whether the eigenvectors are needed or not.
///                If ZNeeded is equal to:
///                 * 0, the eigenvectors are not returned;
///                 * 1, the eigenvectors are returned.
///    IsUpper -   storage format.
///
///Output parameters:
///    D       -   eigenvalues in ascending order.
///                Array whose index ranges within [0..N-1].
///    Z       -   if ZNeeded is equal to:
///                 * 0, Z hasnít changed;
///                 * 1, Z contains the eigenvectors.
///                Array whose indexes range within [0..N-1, 0..N-1].
///                The eigenvectors are stored in the matrix columns.
///Result:
///    True, if the algorithm has converged.
///    False, if the algorithm hasn't converged (rare case).
    function  sevd(const a: PDouble; n, zneeded: Integer; out Res: LongBool;
                   out w: PDoubleArray; out z: IDoubleMatrix): HRESULT; stdcall;
  end;


//__interface INoise : public ILastMathError
{
	SAFECALL normal(const ae_int_t n, const double ampl, const double **noise);
}

 INoise = interface(ILastMathError)
    function  normal(n: Integer; ampl: Double; out noise: PDoubleArray): HRESULT; stdcall;
 end;


// __interface IResample : public ILastMathError
{
	SAFECALL Resample(const double* x, const double* y, const ae_int_t n,  const double* newX, const ae_int_t newN, const double** newY);
}

 IResample = interface(ILastMathError)
    function  Resample(const x, y: PDouble; n: Integer; const newX: PDouble; newN: Integer; out newY: PDoubleArray): HRESULT; stdcall;
 end;


// __interface Ispline : public ILastMathError
{
	SAFECALL buld(const double* x, const double* y, const ae_int_t n);
	SAFECALL get(const double x, double& y);
}

 ISpline = interface(ILastMathError)
    function buld(x,y: PDouble; n: Integer): HRESULT; stdcall;
    function get(x: Double; out y: Double): HRESULT; stdcall;
 end;


{$WARN SYMBOL_PLATFORM OFF}
procedure RbfFactory(out Rbf: IRbf); cdecl; external 'matlab.dll' delayed;
procedure BaryCentricFactory(out BaryCentric: IBaryCentric); cdecl; external 'matlab.dll' delayed;
procedure FourierFactory(out Fourier: IFourier); cdecl; external 'matlab.dll' delayed;
procedure ClusterizerFactory(out Clusterizer: IClusterizer); cdecl; external 'matlab.dll' delayed;
procedure LSFittingFactory(out LSFitting: ILSFitting); cdecl; external 'matlab.dll' delayed;
procedure LMFittingFactory(out LMFitting: ILMFitting); cdecl; external 'matlab.dll' delayed;
procedure ToDoubleMatrix(Src: Pointer; out mtx: IDoubleMatrix); cdecl; external 'matlab.dll' delayed;
procedure EquationsFactory(out Equations: IEquations); cdecl; external 'matlab.dll' delayed;
procedure WaveletFactory(out wavelet: Iwavelet); cdecl; external 'matlab.dll' delayed;
procedure EigFactory(out eig: Ieig); cdecl; external 'matlab.dll' delayed;
procedure NoiseFactory(out Noise: INoise); cdecl; external 'matlab.dll' delayed;
procedure ResampleFactory(out Resample: IResample); cdecl; external 'matlab.dll' delayed;
procedure SplineFactory(out Spline: ISpline); cdecl; external 'matlab.dll' delayed;
{$WARN SYMBOL_PLATFORM ON}

procedure CheckMath(lme: ILastMathError; res: HRESULT);

implementation

procedure CheckMath(lme: ILastMathError; res: HRESULT);
 var
  er: PAnsiChar;
begin
  if res = S_OK then Exit;
  lme.GetLastError(er);
  raise EMatLabException.Create(String(er));
end;

end.
