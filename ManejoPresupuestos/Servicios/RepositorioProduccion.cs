using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioProduccion
    {
        Task<ResultProcedureGeneric> InitPorPedido(int usuarioId, int pedidoId);
        Task<IEnumerable<ProduccionItemRow>> ObtenerPorPedido(int usuarioId, int pedidoId);
        Task<IEnumerable<ProduccionAccionDisponible>> AccionesDisponibles(int usuarioId, int produccionItemId);
        Task<ResultProcedureGeneric> CambiarEstatusItem(int usuarioId, int produccionItemId, int haciaEstatusId, string? notas);
        Task<IEnumerable<ProduccionEstatus>> ObtenerEstatus();
        Task<ResultProcedureGeneric> ActualizarItemDatos(int usuarioId, ProduccionActualizarDatosViewModel modelo);

    }

    public class RepositorioProduccion : IRepositorioProduccion
    {
        private readonly string connectionString;

        public RepositorioProduccion(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<ResultProcedureGeneric> InitPorPedido(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procProduccionInitPorPedido",
                new { PedidoId = pedidoId, loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<ProduccionItemRow>> ObtenerPorPedido(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<ProduccionItemRow>(
                "dbo.procProduccionObtenerPorPedido",
                new { PedidoId = pedidoId, loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<ProduccionAccionDisponible>> AccionesDisponibles(int usuarioId, int produccionItemId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<ProduccionAccionDisponible>(
                "dbo.procProduccionAccionesDisponibles",
                new { ProduccionItemId = produccionItemId, loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> CambiarEstatusItem(int usuarioId, int produccionItemId, int haciaEstatusId, string? notas)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procProduccionCambiarEstatusItem",
                new { ProduccionItemId = produccionItemId, HaciaEstatusId = haciaEstatusId, Notas = notas ?? "", loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<ProduccionEstatus>> ObtenerEstatus()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<ProduccionEstatus>(
                @"SELECT ProduccionEstatusId, Nombre, Orden, BadgeClass
                  FROM dbo.TblProduccionEstatus (NOLOCK)
                  WHERE EstaActivo = 1
                  ORDER BY Orden ASC;"
            );
        }

        public async Task<ResultProcedureGeneric> ActualizarItemDatos(int usuarioId, ProduccionActualizarDatosViewModel modelo)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procProduccionActualizarItemDatos",
                new
                {
                    ProduccionItemId = modelo.ProduccionItemId,
                    ImpresoraId = (int?)modelo.ImpresoraId,
                    NotasOperativas = modelo.NotasOperativas ?? "",
                    PesoEstimadoGr = (decimal?)modelo.PesoEstimadoGr,
                    PesoRealGr = (decimal?)modelo.PesoRealGr,
                    FechaInicio = (DateTime?)modelo.FechaInicio,
                    FechaFin = (DateTime?)modelo.FechaFin,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

    }
}
