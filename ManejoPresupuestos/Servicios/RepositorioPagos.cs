using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioPagos
    {
        Task<IEnumerable<Pago>> ObtenerPorCotizacion(int usuarioId, int cotizacionId);
        Task<Pago?> ObtenerPorId(int usuarioId, int cotizacionId, int pagoId);
        Task<ResultProcedureGeneric> Guardar(int usuarioId, PagoEdicionViewModel modelo);
        Task<ResultProcedureGeneric> Borrar(int usuarioId, int cotizacionId, int pagoId);
        Task<IEnumerable<PagoTipo>> ObtenerTipos();
    }

    public class RepositorioPagos : IRepositorioPagos
    {
        private readonly string connectionString;

        public RepositorioPagos(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Pago>> ObtenerPorCotizacion(int usuarioId, int cotizacionId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Pago>(
                "dbo.procObtenerPagos",
                new
                {
                    CotizacionId = cotizacionId,
                    ElementoObtenerId = 0,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Pago?> ObtenerPorId(int usuarioId, int cotizacionId, int pagoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Pago>(
                "dbo.procObtenerPagos",
                new
                {
                    CotizacionId = cotizacionId,
                    ElementoObtenerId = pagoId,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> Guardar(int usuarioId, PagoEdicionViewModel modelo)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraPago",
                new
                {
                    ElementoAlterarId = modelo.PagoId,
                    CotizacionId = modelo.CotizacionId,
                    PagoTipoId = modelo.PagoTipoId,
                    Monto = modelo.Monto,
                    FechaPago = modelo.FechaPago,
                    Metodo = modelo.Metodo,
                    Referencia = modelo.Referencia,
                    Notas = modelo.Notas,
                    loginId = usuarioId,
                    Actualizar = modelo.PagoId == 0 ? 0 : 1,
                    Borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> Borrar(int usuarioId, int cotizacionId, int pagoId)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraPago",
                new
                {
                    ElementoAlterarId = pagoId,
                    CotizacionId = cotizacionId,
                    PagoTipoId = 1,
                    Monto = 1m,
                    FechaPago = DateTime.Now,
                    Metodo = "",
                    Referencia = "",
                    Notas = "",
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<PagoTipo>> ObtenerTipos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<PagoTipo>(
                "dbo.procObtenerPagoTipos",
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
