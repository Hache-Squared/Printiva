using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioPedidoEstatus
    {
        Task<IEnumerable<PedidoEstatus>> ObtenerTodos();
    }

    public class RepositorioPedidoEstatus : IRepositorioPedidoEstatus
    {
        private readonly string connectionString;

        public RepositorioPedidoEstatus(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<PedidoEstatus>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<PedidoEstatus>(
                "procObtenerPedidoEstatus",
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
