using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
using Newtonsoft.Json;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioCotizaciones
    {
        Task<IEnumerable<CotizacionIndexRow>> ObtenerTodos(int usuarioId, int pedidoId = 0);
        Task<CotizacionIndexRow?> ObtenerPorId(int usuarioId, int cotizacionId);
        Task<IEnumerable<CotizacionItem>> ObtenerItems(int usuarioId, int cotizacionId);
        Task<ResultProcedureGeneric> GuardarCotizacion(int usuarioId, CotizacionEdicionViewModel modelo);
        Task<ResultProcedureGeneric> GuardarItems(int usuarioId, int cotizacionId, IEnumerable<CotizacionItemEdicionViewModel> items);
        Task<ResultProcedureGeneric> Borrar(int usuarioId, int cotizacionId);
        Task<IEnumerable<CotizacionEstatus>> ObtenerEstatus();
    }

    public class RepositorioCotizaciones : IRepositorioCotizaciones
    {
        private readonly string connectionString;

        public RepositorioCotizaciones(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<CotizacionIndexRow>> ObtenerTodos(int usuarioId, int pedidoId = 0)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CotizacionIndexRow>(
                "dbo.procObtenerCotizaciones",
                new
                {
                    ElementoObtenerId = 0,
                    PedidoId = pedidoId,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<CotizacionIndexRow?> ObtenerPorId(int usuarioId, int cotizacionId)
        {
            if (cotizacionId <= 0) return null;
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<CotizacionIndexRow>(
                "dbo.procObtenerCotizaciones",
                new
                {
                    ElementoObtenerId = cotizacionId,
                    PedidoId = 0,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<CotizacionItem>> ObtenerItems(int usuarioId, int cotizacionId)
        {
            if (cotizacionId <= 0) return Enumerable.Empty<CotizacionItem>();

            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CotizacionItem>(
                "dbo.procObtenerCotizacionItems",
                new
                {
                    CotizacionId = cotizacionId,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> GuardarCotizacion(int usuarioId, CotizacionEdicionViewModel modelo)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraCotizacion",
                new
                {
                    ElementoAlterarId = modelo.CotizacionId,
                    PedidoId = modelo.PedidoId,
                    CotizacionEstatusId = modelo.CotizacionEstatusId,
                    FechaVigencia = modelo.FechaVigencia,
                    Notas = modelo.Notas,
                    loginId = usuarioId,
                    Actualizar = modelo.CotizacionId == 0 ? 0 : 1,
                    Borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> GuardarItems(int usuarioId, int cotizacionId, IEnumerable<CotizacionItemEdicionViewModel> items)
        {
            using var connection = new SqlConnection(connectionString);

            var json = JsonConvert.SerializeObject(items.Select(x => new
            {
                x.CotizacionItemId,
                x.ConceptoTipoId,
                ProductoId = x.ProductoId ?? 0,
                x.Concepto,
                x.Cantidad,
                x.PrecioUnitario,
                x.Notas
            }));

            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraCotizacionItemsRelacion",
                new
                {
                    loginId = usuarioId,
                    CotizacionId = cotizacionId,
                    Json = json
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> Borrar(int usuarioId, int cotizacionId)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraCotizacion",
                new
                {
                    ElementoAlterarId = cotizacionId,
                    PedidoId = 0,
                    CotizacionEstatusId = 1,
                    FechaVigencia = (DateTime?)null,
                    Notas = "",
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<CotizacionEstatus>> ObtenerEstatus()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CotizacionEstatus>(
                @"SELECT CotizacionEstatusId, Nombre FROM dbo.TblCotizacionesEstatus (NOLOCK) ORDER BY CotizacionEstatusId ASC"
            );
        }
    }
}
