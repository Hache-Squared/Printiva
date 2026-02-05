using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioPedidos
    {
        Task<IEnumerable<Pedido>> ObtenerTodos(int usuarioId);
        Task<Pedido?> ObtenerPorId(int usuarioId, int pedidoId);
        Task<IEnumerable<PedidoItem>> ObtenerItems(int usuarioId, int pedidoId);
        Task<int> Crear(int usuarioId, PedidoCreacionViewModel pedido);
        Task Actualizar(int usuarioId, PedidoCreacionViewModel pedido);
        Task Borrar(int usuarioId, int pedidoId);
        Task<IEnumerable<PedidoAccionDisponible>> ObtenerAccionesDisponibles(int usuarioId, int pedidoId);
        Task<ResultProcedureGeneric> CambiarEstatus(int usuarioId, int pedidoId, int haciaEstatusId, string? notas);
        Task<IEnumerable<PedidoKanbanCard>> ObtenerKanban(int usuarioId, int clienteId = 0, string? q = null, bool soloPendientes = false);
        Task<ResultProcedureGeneric> OcultarEnKanban(int usuarioId, int pedidoId);
    }

    public class RepositorioPedidos : IRepositorioPedidos
    {
        private readonly string connectionString;

        public RepositorioPedidos(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Pedido>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Pedido>(
                "procObtenerPedidos",
                new { loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Pedido?> ObtenerPorId(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Pedido>(
                "procObtenerPedidos",
                new { loginId = usuarioId, elementoObtenerId = pedidoId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<PedidoItem>> ObtenerItems(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<PedidoItem>(
                "procObtenerPedidoItems",
                new { loginId = usuarioId, pedidoId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<int> Crear(int usuarioId, PedidoCreacionViewModel pedido)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();
            using var tx = connection.BeginTransaction();

            var pedidoId = await connection.QuerySingleAsync<int>(
                "procCrearPedido",
                new
                {
                    loginId = usuarioId,
                    clienteId = pedido.ClienteId,
                    pedidoEstatusId = pedido.PedidoEstatusId,
                    fechaEntregaEstimada = pedido.FechaEntregaEstimada,
                    notas = pedido.Notas,
                    totalEstimado = pedido.TotalEstimado
                },
                commandType: System.Data.CommandType.StoredProcedure,
                transaction: tx
            );

            foreach (var item in pedido.Items.Where(x => x.ProductoId > 0 && x.Cantidad > 0))
            {
                await connection.ExecuteAsync(
                    @"
                    INSERT INTO dbo.TblPedidoItems
                    (PedidoId, ProductoId, Cantidad, PrecioUnitarioEstimado, Notas)
                    VALUES
                    (@PedidoId, @ProductoId, @Cantidad, @PrecioUnitarioEstimado, @Notas);
                    ",
                    new
                    {
                        PedidoId = pedidoId,
                        item.ProductoId,
                        item.Cantidad,
                        item.PrecioUnitarioEstimado,
                        item.Notas
                    },
                    transaction: tx
                );
            }

            tx.Commit();
            return pedidoId;
        }

        public async Task Actualizar(int usuarioId, PedidoCreacionViewModel pedido)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();
            using var tx = connection.BeginTransaction();

            await connection.ExecuteAsync(
                "procActualizarPedido",
                new
                {
                    loginId = usuarioId,
                    pedidoId = pedido.PedidoId,
                    clienteId = pedido.ClienteId,
                    pedidoEstatusId = pedido.PedidoEstatusId,
                    fechaEntregaEstimada = pedido.FechaEntregaEstimada,
                    notas = pedido.Notas,
                    totalEstimado = pedido.TotalEstimado
                },
                commandType: System.Data.CommandType.StoredProcedure,
                transaction: tx
            );

            await connection.ExecuteAsync(
                "procReemplazarPedidoItems",
                new
                {
                    loginId = usuarioId,
                    pedidoId = pedido.PedidoId
                },
                commandType: System.Data.CommandType.StoredProcedure,
                transaction: tx
            );

            foreach (var item in pedido.Items.Where(x => x.ProductoId > 0 && x.Cantidad > 0))
            {
                await connection.ExecuteAsync(
                    @"
                    INSERT INTO dbo.TblPedidoItems
                    (PedidoId, ProductoId, Cantidad, PrecioUnitarioEstimado, Notas)
                    VALUES
                    (@PedidoId, @ProductoId, @Cantidad, @PrecioUnitarioEstimado, @Notas);
                    ",
                    new
                    {
                        PedidoId = pedido.PedidoId,
                        item.ProductoId,
                        item.Cantidad,
                        item.PrecioUnitarioEstimado,
                        item.Notas
                    },
                    transaction: tx
                );
            }

            tx.Commit();
        }

        public async Task Borrar(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.ExecuteAsync(
                "procBorrarPedido",
                new { loginId = usuarioId, pedidoId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<PedidoAccionDisponible>> ObtenerAccionesDisponibles(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<PedidoAccionDisponible>(
                "dbo.procPedidoAccionesDisponibles",
                new
                {
                    PedidoId = pedidoId,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> CambiarEstatus(int usuarioId, int pedidoId, int haciaEstatusId, string? notas)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procPedidoCambiarEstatus",
                new
                {
                    PedidoId = pedidoId,
                    HaciaEstatusId = haciaEstatusId,
                    Notas = notas ?? "",
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<PedidoKanbanCard>> ObtenerKanban(int usuarioId, int clienteId = 0, string? q = null, bool soloPendientes = false)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<PedidoKanbanCard>(
                "dbo.procObtenerPedidosKanban",
                new
                {
                    loginId = usuarioId,
                    ClienteId = clienteId,
                    q = q ?? "",
                    SoloPendientes = soloPendientes ? 1 : 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> OcultarEnKanban(int usuarioId, int pedidoId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procPedidoOcultarEnKanban",
                new { loginId = usuarioId, PedidoId = pedidoId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

    }
}
