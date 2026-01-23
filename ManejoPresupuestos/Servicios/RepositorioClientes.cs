using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioClientes
    {
        Task<IEnumerable<Cliente>> ObtenerTodos(int usuarioId);
        Task<Cliente?> ObtenerPorId(int usuarioId, int id);
        Task<int> Crear(int usuarioId, Cliente cliente);
    }

    public class RepositorioClientes : IRepositorioClientes
    {
        private readonly string connectionString;

        public RepositorioClientes(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Cliente>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Cliente>(
                "procObtenerClientes",
                new { loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Cliente?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Cliente>(
                "procObtenerClientes",
                new { loginId = usuarioId, elementoObtenerId = id },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<int> Crear(int usuarioId, Cliente cliente)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                INSERT INTO dbo.TblClientes
                (UsuarioId, Nombre, Telefono, Instagram, WhatsApp, Email, Direccion, FechaCreacion)
                VALUES
                (@UsuarioId, @Nombre, @Telefono, @Instagram, @WhatsApp, @Email, @Direccion, @FechaCreacion);
                SELECT CAST(SCOPE_IDENTITY() AS INT);
                ",
                new
                {
                    UsuarioId = usuarioId,
                    cliente.Nombre,
                    cliente.Telefono,
                    cliente.Instagram,
                    cliente.WhatsApp,
                    cliente.Email,
                    cliente.Direccion,
                    FechaCreacion = DateTime.Now
                }
            );

            return id;
        }
    }
}
